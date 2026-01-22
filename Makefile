.PHONY: help test docs docs-serve build clean format format-julia format-cpp

JULIA ?= julia

help:
	@echo "Semigroups.jl Makefile"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  test        Run the test suite"
	@echo "  docs        Build documentation"
	@echo "  docs-serve  Build and serve documentation locally"
	@echo "  build       Build C++ bindings"
	@echo "  clean       Clean build artifacts"
	@echo "  format      Format Julia and C++ code"
	@echo "  format-julia  Format Julia code only"
	@echo "  format-cpp    Format C++ code only"

test:
	$(JULIA) --project=. -e 'using Pkg; Pkg.test()'

docs:
	$(JULIA) --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
	$(JULIA) --project=docs docs/make.jl

docs-serve: docs
	$(JULIA) --project=docs -e 'using Pkg; Pkg.add("LiveServer")'
	$(JULIA) --project=docs -e 'using LiveServer; serve(dir="docs/build")'

build:
	$(JULIA) --project=. -e 'using Pkg; Pkg.build("Semigroups")'

clean:
	rm -rf docs/build
	rm -rf deps/build
	rm -f deps/lib/*.dylib deps/lib/*.so

format: format-julia format-cpp

format-julia:
	$(JULIA) -e 'using Pkg; Pkg.add("JuliaFormatter")'
	$(JULIA) -e 'using JuliaFormatter; format("src"); format("test"); format("docs")'

format-cpp:
	find deps/src -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i
