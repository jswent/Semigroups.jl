# Directions for updating Semigroups.jl

`Semigroups.jl` depends on the [libsemigroups](https://github.com/libsemigroups/libsemigroups) C++ library and some C++ glue code
found in the `deps/src/` directory. Compiled versions of each are distributed to
users as binary artifacts via the Julia "JLL" packages `libsemigroups_jll` and
`libsemigroups_julia_jll` respectively.

The build scripts for these JLL packages can be found here:

- <https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/libsemigroups/build_tarballs.jl>
- <https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/libsemigroups_julia/build_tarballs.jl>

The resulting JLL packages:

- <https://github.com/JuliaBinaryWrappers/libsemigroups_jll.jl>
- <https://github.com/JuliaBinaryWrappers/libsemigroups_julia_jll.jl>

The sources:

- `libsemigroups` sources: <https://github.com/libsemigroups/libsemigroups>
- `libsemigroups_julia` sources: `deps/src/` directory of `Semigroups.jl`

[libsemigroups]: https://github.com/libsemigroups/libsemigroups

## Version compatibility

Starting with 0.1.2, `libsemigroups_julia_jll` declares an exact runtime
compatibility constraint on the `libsemigroups_jll` version it was built
against. Preserve this policy for future releases by setting both the build
dependency and its `compat` in the wrapper's Yggdrasil recipe, for example:

```julia
Dependency("libsemigroups_jll", v"3.6.1"; compat="=3.6.1")
```

The build version alone does not constrain runtime resolution. Every kernel
upgrade requires a new wrapper release, even if `deps/src/` has not changed.
Wrapper versions are independent of `Semigroups.jl` versions; Julia-only
changes may reuse the existing wrapper.

For example, `Semigroups.jl` 0.1.3 requires wrapper 0.1.2 or later in the 0.1
series and core 3.6.1. Wrapper 0.1.2 enforces core 3.6.1. A new recipe does not
retroactively constrain older wrapper releases; corrections to their
compatibility metadata require a separate General registry change.

## Checking a release

Use a fresh checkout without a `Manifest.toml` or local build artifacts, then
resolve the registered dependencies and check the published binaries:

```shell
julia --startup-file=no --project=. -e 'using Pkg; Pkg.Registry.update(); Pkg.instantiate()'
julia --startup-file=no --project=. test/check_jll.jl
```

The second command checks that the published wrapper loads its expected core
artifact and reports the same core version it was compiled against. CI runs
this check separately from the main suite so that C++ development can still
test a locally rebuilt wrapper.

Before releasing, also verify that `Semigroups.jl` selects the published
wrapper, then run the full suite in the same Julia process:

```shell
julia --startup-file=no --project=. -e '
    using Semigroups, libsemigroups_julia_jll
    @assert realpath(Semigroups.libsemigroups_julia()) ==
            realpath(libsemigroups_julia_jll.libsemigroups_julia)
    include("test/runtests.jl")
'
```

## Updating just the C++ wrappers

Suppose just the C++ wrappers need to be updated, without any changes to the
`libsemigroups` kernel itself.

1. Commit changes to the `deps/src/` directory.

2. After the changes are merged (and before the next `Semigroups.jl` release),
   update the `libsemigroups_julia` build script with a new version number and
   using the latest commit SHA for the `main` branch of `Semigroups.jl`.

3. Wait for this to be merged into Yggdrasil, and then wait for the registry
   to pick up the new version of `libsemigroups_julia_jll`.

4. Raise the minimum `libsemigroups_julia_jll` version in `Project.toml` to
   the version used in Step 2. Follow [Checking a release](#checking-a-release)
   to verify the registered prebuilt JLLs and run the package tests.

   Version compatibility notation: <https://pkgdocs.julialang.org/v1/compatibility/>

5. After these checks and CI pass, release a new `Semigroups.jl`. This is done
   by pinging JuliaRegistrator in the comments of a commit.
    > See an example of the release comment [here](https://github.com/libsemigroups/Semigroups.jl/commit/eb34e11c46a737eedf1bf58bc3f7dbe07ac6338f#commitcomment-185167266)

After the new version of `Semigroups.jl` is picked up by the registry, it may
be used in further downstream packages.

## Updating the libsemigroups kernel

Suppose the `libsemigroups` kernel needs an update. This involves updating both
build scripts because `libsemigroups_julia_jll` will need to point to the new
`libsemigroups_jll`.

1. Update the `libsemigroups` build script with the commit SHA of the
   `libsemigroups` sources at <https://github.com/libsemigroups/libsemigroups>.

   Any build issues need to be communicated to
   <https://github.com/libsemigroups/libsemigroups> until you get a commit that
   builds on all targets.

2. Wait for the Yggdrasil merge, and wait for the registry.
    > _Note:_ steps 1 and 2 should be handled automatically by the [libsemigroups-yggdrasil-pr](https://github.com/libsemigroups-yggdrasil-pr/) bot

3. Open a separate Yggdrasil PR updating the `libsemigroups_julia` build
   script with a new wrapper version. Set its `libsemigroups_jll` build
   dependency to the new kernel version and add the corresponding exact
   runtime `compat`, as shown above. Keep the wrapper source commit unless
   source changes are also needed.

4. Wait for the wrapper recipe to merge and the new `libsemigroups_julia_jll`
   version to be registered in General.

5. Update both compatibility entries in `Semigroups.jl`'s `Project.toml`:
   pin `libsemigroups_jll` to the new kernel version and raise the minimum
   `libsemigroups_julia_jll` version to the newly registered wrapper. For
   example:

   ```toml
   libsemigroups_jll = "=3.6.1"
   libsemigroups_julia_jll = "0.1.2"
   ```

6. Resolve dependencies in a fresh environment and run the tests against
   the registered prebuilt JLLs, checking the versions and artifact paths
   as described in [Checking a release](#checking-a-release). Release a new
   `Semigroups.jl` version only after these checks and CI pass, using
   JuliaRegistrator as in the wrapper-only release instructions.

## Updating both `libsemigroups_julia` and the libsemigroups kernel

Since updating the `libsemigroups` kernel requires an update to
`libsemigroups_julia`, the steps here are the same as in the previous section.
Just make sure that in Step 3, the commit SHA used to update the
`libsemigroups_julia` build scripts contains all of the desired changes to
`libsemigroups_julia`.

## Building a custom `libsemigroups_jll` locally

For testing purposes one may wish to try out `libsemigroups_jll` changes locally
before submitting them as a PR to Yggdrasil. This can be done as shown in the
following shell script:

```shell
# Change into a clone of the Yggdrasil repository
git clone https://github.com/JuliaPackaging/Yggdrasil
cd Yggdrasil

# record the base path
BASEPATH=$(pwd)

# ensure building macOS binaries will work (you can omit this if you only
# want to build for Linux)
export BINARYBUILDER_AUTOMATIC_APPLE=true

# change into the directory containing the `build_tarballs.jl` we want to build
cd L/libsemigroups

# Now `build_tarballs.jl` can be modified, e.g. to pull a different set of
# sources, use different versions of dependencies, etc.

# ensure BinaryBuilder etc. is installed in the right version
# (ideally use the same Julia version as specified in `.ci/Manifest.toml`)
julia --project=$BASEPATH/.ci -e 'using Pkg; Pkg.instantiate()'

# get list of platforms etc.
julia --project=$BASEPATH/.ci build_tarballs.jl --help

# build and deploy the JLL locally. If you omit the comma-separated
# list of PLATFORMS then it will build for *all* platforms
julia --project=$BASEPATH/.ci build_tarballs.jl PLATFORMS --deploy=local
```

The same procedure works for `libsemigroups_julia_jll` — substitute
`L/libsemigroups_julia` for `L/libsemigroups` above.
