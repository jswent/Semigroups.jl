# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
make.jl - Documentation build script for Semigroups.jl
"""

using Documenter
using Semigroups
using Revise;
Revise.revise()
using Dates

DocMeta.setdocmeta!(Semigroups, :DocTestSetup, :(using Semigroups); recursive = true)

makedocs(;
    modules = [Semigroups],
    sitename = "Semigroups.jl",
    format = Documenter.HTML(;
        canonical = "https://github.com/libsemigroups/Semigroups.jl",
        edit_link = "main",
        assets = String[],
        collapselevel = 1,
        sidebar_sitename = false,
    ),
    pages = [
        "Home" => "index.md",
        "Package Info" => [
            "Installation" => "package-info/installation.md",
            "Authors" => "package-info/authors.md",
            #= "Bibliography" => "package-info/bibliography.md", =# "Exceptions" => "package-info/exceptions.md",
        ],
        "Data Structures" => [
            "Constants" => "data-structures/constants/index.md",
            "Elements" => [
                "Overview" => "data-structures/elements/index.md",
                "Transformations" => [
                    "Overview" => "data-structures/elements/transformations/index.md",
                    "Transf" => "data-structures/elements/transformations/transf.md",
                    "PPerm" => "data-structures/elements/transformations/pperm.md",
                    "Perm" => "data-structures/elements/transformations/perm.md",
                ],
                "Matrix" => [
                    "Overview" => "data-structures/elements/matrix/index.md",
                    "The BMat8 type" => "data-structures/elements/matrix/bmat8.md",
                ],
            ],
            "Orders" => "data-structures/order.md",
            "Presentations" => [
                "Overview" => "data-structures/presentations/index.md",
                "Presentation" => "data-structures/presentations/presentation.md",
                "InversePresentation" => "data-structures/presentations/inverse-presentation.md",
                "Helper functions" => "data-structures/presentations/helpers.md",
                "Examples" => "data-structures/presentations/examples.md",
            ],
            "Word Graphs" => "data-structures/word-graph.md",
            "Paths" => "data-structures/paths.md",
            "Words" => "data-structures/word-range.md",
            "ASCII string words" => "data-structures/string-words.md",
        ],
        "Main Algorithms" => [
            "Overview" => "main-algorithms/index.md",
            "Common congruence helpers" => "main-algorithms/cong-common-helpers.md",
            "Core classes" => [
                "main-algorithms/core-classes/index.md",
                "main-algorithms/core-classes/runner.md",
            ],
            "Froidure-Pin" => [
                "Overview" => "main-algorithms/froidure-pin/index.md",
                "The FroidurePin type" => "main-algorithms/froidure-pin/froidure-pin.md",
                "Helper functions" => "main-algorithms/froidure-pin/helpers.md",
            ],
            "Knuth-Bendix" => [
                "Overview" => "main-algorithms/knuth-bendix/index.md",
                "The KnuthBendix type" => "main-algorithms/knuth-bendix/knuth-bendix.md",
                "Helper functions" => "main-algorithms/knuth-bendix/helpers.md",
            ],
            "Kambites" => [
                "Overview" => "main-algorithms/kambites/index.md",
                "The Kambites type" => "main-algorithms/kambites/kambites.md",
            ],
        ],
    ],
    warnonly = [:missing_docs, :linkcheck, :cross_references],
)

if get(ENV, "DOCS_DEPLOY", "false") == "true"
    deploydocs(
        repo = "github.com/libsemigroups/Semigroups.jl.git",
        devbranch = "main",
        push_preview = true,
    )
end
