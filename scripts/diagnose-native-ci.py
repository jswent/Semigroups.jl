"""OpenAI Codex: bounded native ABI/allocator probes using unchanged main sources."""
import json
import os
from pathlib import Path
import re
import resource
import shlex
import signal
import subprocess
import tempfile

root = Path.cwd()
out = Path(tempfile.mkdtemp(prefix="sg-ci-cause-"))
results = []
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))


def run(label, command, seconds=60, input_text=None, show=True, env=None):
    print("\nPROBE " + label + " " + shlex.join(command), flush=True)
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               stdin=subprocess.PIPE, text=True, start_new_session=True, env=env)
    expired = False
    try:
        output, _ = process.communicate(input=input_text, timeout=seconds)
    except subprocess.TimeoutExpired:
        expired = True
        os.killpg(process.pid, signal.SIGKILL)
        output, _ = process.communicate()
    (out / (label + ".log")).write_text(output)
    if show:
        print(output, flush=True)
    result = {"probe": label, "exit": process.returncode, "timeout": expired}
    results.append(result)
    print(json.dumps(result), flush=True)
    return process.returncode, output


run("compiler-version", ["c++", "-v"])
_, target = run("compiler-target", ["c++", "-Q", "--help=target"], show=False)
print("Target flags:", "\n".join(l for l in target.splitlines()
      if re.search(r"march=|mtune=|mavx|msse", l)), flush=True)
run("operating-system", ["cat", "/etc/os-release"])
print("Compilation environment:", {k: os.environ.get(k) for k in
      ("CC", "CXX", "CPPFLAGS", "CFLAGS", "CXXFLAGS", "LDFLAGS")}, flush=True)
entries = json.loads((root / "deps/build/compile_commands.json").read_text())
entry = next(e for e in entries if e["file"].endswith("/knuth-bendix.cpp"))
print("Exact native compile entry:", json.dumps(entry), flush=True)
raw = shlex.split(entry["command"])
compiler = raw[0]
flags = []
i = 1
while i < len(raw):
    if raw[i] in ("-o", "-c"):
        i += 2
    else:
        flags.append(raw[i])
        i += 1
flags.append("-I" + str(root / "deps/src"))
core = Path("/tmp/sg-core-path").read_text().strip()
source = out / "allocator.cpp"
source.write_text('''// OpenAI Codex: preserve the wrapper's include order and flags.
#include "libsemigroups_julia.hpp"
#include <libsemigroups/obvinf.hpp>
#include <iostream>
int main() {
  std::cout << "EIGEN_MALLOC_ALREADY_ALIGNED=" << EIGEN_MALLOC_ALREADY_ALIGNED
            << " EIGEN_DEFAULT_ALIGN_BYTES=" << EIGEN_DEFAULT_ALIGN_BYTES
            << " sizeof(IsObviouslyInfinite)=" << sizeof(libsemigroups::IsObviouslyInfinite)
            << std::endl;
  {
    libsemigroups::IsObviouslyInfinite ioi(3);
    std::vector<libsemigroups::word_type> rules{{0, 1}, {1, 0}};
    ioi.add_rules_no_checks(std::string("\\0\\1\\2", 3), rules.cbegin(), rules.cend());
    std::cout << "result=" << ioi.result() << "; destroying" << std::endl;
  }
  std::cout << "PASS" << std::endl;
}
''')
code, macros = run("actual-predefines", [compiler, *flags, "-E", "-dM", str(source)], show=False)
print("Relevant predefines:", "\n".join(l for l in macros.splitlines()
      if re.search(r"EIGEN_.*ALIGN|__AVX|__SSE|__GLIBC|__SANITIZE|__GNUC__", l)), flush=True)
for label, extra in [
    ("default", []),
    ("generic", ["-march=x86-64"]),
    ("v3", ["-march=x86-64-v3"]),
    ("v3-allocation1", ["-march=x86-64-v3", "-DEIGEN_MALLOC_ALREADY_ALIGNED=1"]),
]:
    exe = out / label
    rc, _ = run(label + "-compile", [compiler, *flags, *extra, str(source),
                "-L" + core + "/lib", "-Wl,-rpath," + core + "/lib",
                "-lsemigroups", "-o", str(exe)])
    if rc == 0:
        run(label + "-run", [str(exe)], seconds=10)

probe = out / "knuth.jl"
probe.write_text('''# OpenAI Codex: reduce the first failing Knuth-Bendix test.
if "default-abort" in ARGS
    ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 6, C_NULL)
end
if "load-test" in ARGS
    @eval using Test
end
using Semigroups, Libdl
println("wrapper: ", Semigroups.libsemigroups_julia())
println("loaded: ", filter(p -> occursin("semigroups", basename(p)), Libdl.dllist()))
ReportGuard(false) do
    p = Presentation()
    set_alphabet!(p, 3)
    rules = [("ab","ba"), ("ac","ca"), ("aa","a"), ("ac","a"),
             ("ca","a"), ("bb","bb"), ("bc","cb"), ("bbb","b"),
             ("bc","b"), ("cb","b"), ("a","b")]
    w(s) = [Int(c)-Int('a')+1 for c in s]
    for (a,b) in rules
        add_rule_no_checks!(p,w(a),w(b))
    end
    kb = KnuthBendix(twosided,p)
    @assert number_of_active_rules(kb) == 0
    @assert number_of_pending_rules(kb) == 10
    @assert confluent(kb)
    @assert Semigroups.reduce(kb,w("ca")) == w("a")
    @assert Semigroups.reduce(kb,w("ac")) == w("a")
    @assert Semigroups.contains(kb,w("ca"),w("a"))
    @assert Semigroups.contains(kb,w("ac"),w("a"))
    println("calling number_of_classes"); flush(stdout)
    @assert number_of_classes(kb) == POSITIVE_INFINITY
    println("PASS")
end
''')
for label, extra in [("julia-default-handler", []), ("julia-default-abort", ["default-abort"])]:
    run(label, ["julia", "--startup-file=no", "--project=.", str(probe), *extra], seconds=90)
ci_flags = ["--startup-file=no", "--check-bounds=yes", "--compiled-modules=yes", "--depwarn=yes", "--code-coverage=user", "--project=."]
run("julia-ci-flags", ["julia", *ci_flags, str(probe), "default-abort", "load-test"], seconds=120)
suite = "ccall(:signal, Ptr{Cvoid}, (Cint, Ptr{Cvoid}), 6, C_NULL); include(\"test/runtests.jl\")"
run("full-suite-normal-loading", ["julia", *ci_flags, "-e", suite], seconds=240)

# Same existing native binary, with the published JLL redirected to that binary.
# This is an isolated diagnostic depot, not a source or compiler change.
depot = out / "isolated-depot"
(depot / "artifacts").mkdir(parents=True)
artifact = out / "local-wrapper"
artifact.mkdir()
(artifact / "lib").symlink_to(root / "deps/build", target_is_directory=True)
old_hash = Path(Path("/tmp/sg-wrapper-path").read_text().strip()).name
(depot / "artifacts/Overrides.toml").write_text(old_hash + " = " + json.dumps(str(artifact)) + "\n")
isolated_env = dict(os.environ)
isolated_env["JULIA_DEPOT_PATH"] = str(depot) + ":" + Path("/tmp/sg-depots").read_text().strip()
run("julia-only-local", ["julia", *ci_flags, str(probe), "default-abort", "load-test"], seconds=150, env=isolated_env)
run("full-suite-only-local", ["julia", *ci_flags, "-e", suite], seconds=240, env=isolated_env)
print("FINAL RESULTS " + json.dumps(results), flush=True)
