# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

module Semigroups

using CxxWrap
using AbstractAlgebra
import Dates
import Libdl
using Dates: TimePeriod, Nanosecond
using libsemigroups_jll

# ============================================================================
# Debug mode
# ============================================================================

const _debug_mode = Ref(false)
const VERSION_NUMBER = Base.pkgversion(@__MODULE__)


"""
    enable_debug(val::Bool=true)

Enable or disable debug mode for libsemigroups tracing.

When debug mode is enabled, the full C++ stack trace from libsemigroups/jlcxx
is shown instead of only the high-level Julia translation.

# Example
```julia
Semigroups.enable_debug()       # enable debug mode
Semigroups.enable_debug(false)  # disable debug mode
```
"""
enable_debug(val::Bool = true) = (_debug_mode[] = val)

"""
    is_debug() -> Bool

Check if debug mode is enabled for libsemigroups error handling.
"""
is_debug() = _debug_mode[]

# ============================================================================
# Package setup
# ============================================================================

# Setup and library location
include("setup.jl")

# Get the library path - this will build if necessary during precompilation
const _libsemigroups_julia = Ref(Setup.locate_library())
libsemigroups_julia() = _libsemigroups_julia[]

# Low-level CxxWrap bindings
include("LibSemigroups.jl")

# Re-export the low-level module for advanced users
using .LibSemigroups

# Import error handling utilities
include("errors.jl")
using .Errors: LibsemigroupsError, @wrap_libsemigroups_call

# Julia-side wrapper files
include("constants.jl")
include("report.jl")
include("runner.jl")
include("order.jl")
include("word-range.jl")
include("word-graph.jl")
include("paths.jl")
include("presentation.jl")
include("presentation-examples.jl")
include("cong-common.jl")
include("knuth-bendix.jl")
include("todd-coxeter.jl")
include("kambites.jl")

# High-level element types
include("bmat8.jl")
include("transf.jl")

# Algorithm types (must come after element types)
include("froidure-pin.jl")
include("to.jl")

function _version_string(v::Union{Nothing,VersionNumber})
    return isnothing(v) ? "unknown" : string(v)
end

function _path_is_within(path::AbstractString, root::AbstractString)
    try
        rel = relpath(realpath(path), realpath(root))
        return rel == "." || first(splitpath(rel)) != ".."
    catch
        return false
    end
end

function _loaded_libsemigroups_path()
    for path in Libdl.dllist()
        base = basename(path)
        occursin("libsemigroups_julia", base) && continue
        if startswith(base, "libsemigroups.") ||
           base == "libsemigroups.dylib" ||
           base == "libsemigroups.so" ||
           startswith(base, "libsemigroups-")
            return path
        end
    end
    return nothing
end

function _loaded_libsemigroups_version()
    if isdefined(LibSemigroups, :libsemigroups_version)
        try
            return LibSemigroups.libsemigroups_version()
        catch
        end
    end

    path = _loaded_libsemigroups_path()
    if path !== nothing && _path_is_within(path, libsemigroups_jll.artifact_dir)
        return replace(string(Base.pkgversion(libsemigroups_jll)), r"\+.*$" => "")
    end

    try
        return readchomp(`pkg-config --modversion libsemigroups`)
    catch
        return "unknown"
    end
end

function _loaded_libsemigroups_source()
    path = _loaded_libsemigroups_path()
    if path === nothing
        return "unknown"
    elseif _path_is_within(path, libsemigroups_jll.artifact_dir)
        return "JLL"
    else
        return "dev/system"
    end
end

function _libsemigroups_julia_source()
    return Setup.library_source[]
end

function _libsemigroups_julia_version()
    source = _libsemigroups_julia_source()
    if source == "JLL"
        return Setup.jll_version()
    elseif source == "override"
        return "unknown"
    else
        return _version_string(VERSION_NUMBER)
    end
end

function _version_line(
    name::AbstractString,
    version::AbstractString,
    source::AbstractString,
)
    return rpad(name, 21) * " v" * version * " (" * source * ")"
end

function _compact_version_line(
    name::AbstractString,
    version::AbstractString,
    source::AbstractString,
)
    return name * " v" * version * " (" * source * ")"
end

function _print_banner()
    semigroups_version = _version_string(VERSION_NUMBER)
    libsemigroups_version = _loaded_libsemigroups_version()
    libsemigroups_source = _loaded_libsemigroups_source()
    bindings_version = _libsemigroups_julia_version()
    bindings_source = _libsemigroups_julia_source()

    if displaysize(stdout)[2] >= 80
        println(raw"  ____                 _                              ")
        println(raw" / ___|  ___ _ __ ___ (_) __ _ _ __ ___  _   _ _ __  ___")
        println(raw" \___ \ / _ \ '_ ` _ \| |/ _` | '__/ _ \| | | | '_ \/ __|")
        println("  ___) |  __/ | | | | | | (_| | | | (_) | |_| | |_) \\__ \\")
        println(raw" |____/ \___|_| |_| |_|_|\__, |_|  \___/ \__,_| .__/|___/")
        println(raw"                         |___/                |_|")
        println("  Semigroups.jl v$semigroups_version")
        println(
            "  " *
            _version_line("libsemigroups", libsemigroups_version, libsemigroups_source),
        )
        println(
            "  " * _version_line("libsemigroups_julia", bindings_version, bindings_source),
        )
    else
        println(
            "Semigroups.jl v$semigroups_version | " *
            _compact_version_line(
                "libsemigroups",
                libsemigroups_version,
                libsemigroups_source,
            ) *
            " | " *
            _compact_version_line("libsemigroups_julia", bindings_version, bindings_source),
        )
    end
end

function versioninfo(io::IO = stdout)
    semigroups_version = _version_string(VERSION_NUMBER)
    println(io, "Semigroups.jl version $semigroups_version")
    println(io, "  loaded:")
    println(
        io,
        "    " * _version_line(
            "libsemigroups",
            _loaded_libsemigroups_version(),
            _loaded_libsemigroups_source(),
        ),
    )
    println(
        io,
        "    " * _version_line(
            "libsemigroups_julia",
            _libsemigroups_julia_version(),
            _libsemigroups_julia_source(),
        ),
    )
end

# Module initialization
function __init__()
    if AbstractAlgebra.should_show_banner()
        _print_banner()
    end
end

# ============================================================================
# Exports
# ============================================================================

export enable_debug, is_debug, LibsemigroupsError, ReportGuard
export UNDEFINED, POSITIVE_INFINITY, NEGATIVE_INFINITY, LIMIT_MAX
export Runner, RunnerState
export CongruenceCommon, Congruence
export STATE_NEVER_RUN, STATE_RUNNING_TO_FINISH, STATE_RUNNING_FOR
export STATE_RUNNING_UNTIL, STATE_TIMED_OUT, STATE_STOPPED_BY_PREDICATE
export STATE_NOT_RUNNING, STATE_DEAD
export run!, run_for!, run_until!, init!, kill!
export finished, started, running, timed_out, stopped, dead
export stopped_by_predicate, running_for, running_until
export current_state, running_for_how_long
export report_why_we_stopped, string_why_we_stopped
export congruence_kind, onesided, twosided
export tril, tril_FALSE, tril_TRUE, tril_unknown, tril_to_bool
export is_undefined, is_positive_infinity, is_negative_infinity, is_limit_max

# Order enum and comparators
export Order, ORDER_NONE, ORDER_SHORTLEX, ORDER_LEX, ORDER_RECURSIVE
export lex_less, shortlex_less, recursive_path_less
export weighted_shortlex_less, weighted_lex_less

# WordRange
export WordRange, alphabet_size, set_alphabet_size!
export first_word, last_word, set_first!, set_last!
export order, set_order!, set_upper_bound!, set_min!, set_max!
export number_of_words, random_word
export next!, at_end, valid, init!, size_hint, upper_bound

# WordGraph
export WordGraph, number_of_nodes, out_degree, target, target!, add_nodes!

# Paths
export Paths, paths, source, source!, min!, max!, order!
export current_target, word_graph, throw_if_source_undefined

# Presentation
export Presentation, alphabet, set_alphabet!, alphabet_from_rules!
export letter, index_of, in_alphabet
export contains_empty_word, set_contains_empty_word!
export add_generator!, remove_generator!
export add_rule!, add_rule_no_checks!, add_rules!
export number_of_rules, rule, rule_lhs, rule_rhs, rules, clear_rules!
export throw_if_alphabet_has_duplicates, throw_if_letter_not_in_alphabet
export throw_if_bad_rules, throw_if_bad_alphabet_or_rules
export length_of, longest_rule_length, shortest_rule_length
export longest_rule_index, shortest_rule_index
export first_unused_letter, index_rule, is_rule
export is_normalized, are_rules_sorted, contains_rule
export throw_if_odd_number_of_rules, throw_if_bad_inverses
export normalize_alphabet!, change_alphabet!, sort_rules!, sort_each_rule!
export add_identity_rules!, add_zero_rules!, add_inverse_rules!
export replace_subword!, replace_word!, replace_word_with_new_generator!
export remove_duplicate_rules!, remove_trivial_rules!
export to_gap_string
export InversePresentation, set_inverses!, inverses, inverse_of
export throw_if_bad_alphabet_rules_or_inverses

# presentation::examples
export symmetric_group
export alternating_group, braid_group, not_symmetric_group
export full_transformation_monoid, partial_transformation_monoid
export symmetric_inverse_monoid, cyclic_inverse_monoid
export order_preserving_monoid, order_preserving_cyclic_inverse_monoid
export orientation_preserving_monoid, orientation_preserving_reversing_monoid
export partition_monoid, partial_brauer_monoid, brauer_monoid
export singular_brauer_monoid, temperley_lieb_monoid, motzkin_monoid
export partial_isometries_cycle_graph_monoid, uniform_block_bijection_monoid
export dual_symmetric_inverse_monoid, stellar_monoid, zero_rook_monoid
export abacus_jones_monoid
export plactic_monoid, chinese_monoid, hypo_plactic_monoid, stylic_monoid
export special_linear_group_2
export fibonacci_semigroup, monogenic_semigroup, rectangular_band
export sigma_plactic_monoid
export renner_type_B_monoid, renner_type_D_monoid
export not_renner_type_B_monoid, not_renner_type_D_monoid

# KnuthBendix
export KnuthBendix
export overlap_ABC, overlap_AB_BC, overlap_MAX_AB_BC
export max_pending_rules, max_pending_rules!
export check_confluence_interval, check_confluence_interval!
export max_overlap, max_overlap!, max_rules, max_rules!
export overlap_policy, overlap_policy!
export number_of_active_rules, number_of_inactive_rules
export number_of_pending_rules, total_rules
export confluent, confluent_known, number_of_classes
export kind, number_of_generating_pairs, generating_pairs, presentation
export reduce_no_run, currently_contains
export add_generating_pair!
export active_rules, gilman_graph, gilman_graph_node_labels
export by_overlap_length!, is_reduced, redundant_rule
export normal_forms, partition, non_trivial_classes

# ToddCoxeter
export ToddCoxeter
export strategy_hlt,
    strategy_felsch, strategy_CR, strategy_R_over_C, strategy_Cr, strategy_Rc
export lookahead_extent_full, lookahead_extent_partial
export lookahead_style_hlt, lookahead_style_felsch
export def_policy_no_stack_if_no_space, def_policy_purge_from_top, def_policy_purge_all
export def_policy_discard_all_if_no_space, def_policy_unlimited
export def_version_one, def_version_two
export strategy, strategy!
export lookahead_extent, lookahead_extent!
export lookahead_style, lookahead_style!
export save, save!
export use_relations_in_extra, use_relations_in_extra!
export lower_bound, lower_bound!
export def_version, def_version!
export def_policy, def_policy!
export standardize!, is_standardized, current_word_graph, word_graph
export current_index_of, word_of, current_word_of
export is_non_trivial, tc_redundant_rule

# Kambites
export Kambites
export small_overlap_class, current_small_overlap_class, throw_if_not_C4

# Transformation types and functions
export Transf, PPerm, Perm
export degree, rank, image, domain, inverse
export increase_degree_by!, swap!
export left_one, right_one

# FroidurePin
export FroidurePin, current_size, number_of_generators, enumerate!
export generator, sorted_at
export sorted_position, to_sorted_position
export closure!, copy_closure, copy_add_generators, reserve!
export batch_size, set_batch_size!
export current_position
export contains_one, currently_contains_one, is_idempotent
export prefix, suffix, first_letter, final_letter, fast_product
export number_of_idempotents, number_of_elements_of_length
export current_number_of_rules, current_max_word_length
export position_of_generator, current_length, word_length
export product_by_reduction
export rules, current_rules, normal_forms, current_normal_forms
export idempotents, sorted_elements
export minimal_factorisation, current_minimal_factorisation, factorisation
export right_cayley_graph, current_right_cayley_graph
export left_cayley_graph, current_left_cayley_graph
export to_element, equal_to

# BMat8
export BMat8, to_int, swap!, degree, random, row_space_basis
export col_space_basis, col_space_size, is_regular_element, minimum_dim
export number_of_cols, number_of_rows, row_space_size, rows

end # module Semigroups
