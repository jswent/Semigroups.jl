# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
runner.jl - Julia wrappers for libsemigroups Runner base class

This file provides low-level Julia wrappers for the C++ Runner class exposed
via CxxWrap. Runner is an abstract base class providing algorithm execution
control (run, run_for, timeout, stop, etc.) used by FroidurePinBase and other
algorithm classes.
"""

# ============================================================================
# Type aliases
# ============================================================================

"""
    Runner

Abstract class for derived classes that run an algorithm.
  
Many of the classes in Semigroups.jl implementing the algorithms that are the
reason for the existence of this library, are derived from [`Runner`](@ref).
The [`Runner`](@ref) class exists to collect various common tasks required by
such a derived class with a possibly long running [`run!`](@ref).

These common tasks include:
* running for a given amount of time ([`run_for!`](@ref))
* running until a nullary predicate is true ([`run_until!`](@ref))
* checking the status of the algorithm: has it [`started`](@ref)? [`finished`](@ref)? been killed by another thread ([`dead`](@ref))? has it timed out ([`timed_out`](@ref))? has it [`stopped`](@ref) for any reason?
* permit the function [`run!`](@ref) to be killed from another thread ([`kill!`](@ref)).
"""
abstract type Runner end

_native(r::Runner) = r.cxx_obj

"""
    RunnerState

Enum type for the state of a [`Runner`](@ref). Possible values:

- `STATE_NEVER_RUN` - the runner has never been run
- `STATE_RUNNING_TO_FINISH` - running to completion
- `STATE_RUNNING_FOR` - running for a bounded duration
- `STATE_RUNNING_UNTIL` - running until a predicate is satisfied
- `STATE_TIMED_OUT` - the last `run_for!` call timed out
- `STATE_STOPPED_BY_PREDICATE` - the last `run_until` call was stopped
- `STATE_NOT_RUNNING` - the runner is not currently running
- `STATE_DEAD` - the runner was killed
"""
const RunnerState = LibSemigroups.state

const STATE_NEVER_RUN = LibSemigroups.state_never_run
const STATE_RUNNING_TO_FINISH = LibSemigroups.state_running_to_finish
const STATE_RUNNING_FOR = LibSemigroups.state_running_for
const STATE_RUNNING_UNTIL = LibSemigroups.state_running_until
const STATE_TIMED_OUT = LibSemigroups.state_timed_out
const STATE_STOPPED_BY_PREDICATE = LibSemigroups.state_stopped_by_predicate
const STATE_NOT_RUNNING = LibSemigroups.state_not_running
const STATE_DEAD = LibSemigroups.state_dead

# ============================================================================
# Core algorithm control
# ============================================================================

"""
    run!(r::Runner)

Run until [`finished`](@ref).

Run the main algorithm implemented by a derived class of [`Runner`](@ref).
"""
run!(r::Runner) = (@wrap_libsemigroups_call LibSemigroups.run!(_native(r)); r)

"""
    run_for!(r::Runner, t::TimePeriod)

Run for a specified amount of time.

For this to work it is necessary to periodically check if
[`timed_out`](@ref) returns `true`, and to stop if it is, in the
[`run!`](@ref) method of any subtype of [`Runner`](@ref).

# Arguments
- `t::TimePeriod`:  the duration to run for.

# Examples
```julia
run_for!(r, Second(1))
run_for!(r, Millisecond(500))
```
"""
function run_for!(r::Runner, t::TimePeriod)
    ns = convert(Nanosecond, t)
    Dates.value(ns) >= 0 ||
        throw(ArgumentError("run_for! requires a non-negative duration, got $t"))
    @wrap_libsemigroups_call LibSemigroups.run_for!(_native(r), Int64(Dates.value(ns)))
end

function run_until!(f::Function, r::Runner)
    sf = @safe_cfunction($f, Cuchar, ())
    GC.@preserve sf @wrap_libsemigroups_call LibSemigroups.run_until!(_native(r), sf)
end

"""
    run_until!(r::Runner, f::Function)

Run until a nullary predicate returns `true` or [`finished`](@ref).

This function runs the algorithm until the nullary predicate `f` returns `true`
or the algorithm [`finished`](@ref). 

# Arguments 
- `f::Function`: a function with `0` arguments returning `true` or `false`

Supports do-block syntax:

```julia
run_until!(r) do
    some_condition(r)
end
```
"""
run_until!(r::Runner, f::Function) = run_until!(f, r)


"""
    init!(r::Runner) -> Runner

Initialize an existing Runner object.

This function puts a Runner object back into the same state as if it
had been newly default constructed.

!!! note 
    This function is not thread-safe.

# See also
[`Runner`](@ref)
"""
init!(r::Runner) = (@wrap_libsemigroups_call LibSemigroups.init!(_native(r)); r)

# ============================================================================
# State queries
# ============================================================================

"""
    finished(r::Runner) -> Bool

Check if [`run!(::Runner)`](@ref) has been run to completion or not.

Returns `true` if [`run!`](@ref) has been run to completion; and `false` if not.

# See also
"""
finished(r::Runner) = LibSemigroups.finished(_native(r))

"""
    Base.success(r::Runner) -> Bool

Check if [`run!`](@ref) has been run to completion successfully.

Returns `true` if [`run!`](@ref) has been run to completion and it was
successful. The default implementation is to just call [`finished`](@ref).

This extends `Base.success` (which checks process exit status) to work with
libsemigroups [`Runner`](@ref) types. 
"""
Base.success(r::Runner) = LibSemigroups.success(_native(r))

"""
    started(r::Runner) -> Bool

Check if [`run!`](@ref) has been called at least once before.

Returns `true` if [`run!`](@ref) has started to run (it can be running or
not).

# See also
[`finished`](@ref)
"""
started(r::Runner) = LibSemigroups.started(_native(r))

"""
    running(r::Runner) -> Bool

Check if currently running.

Returns `true` if [`run!`](@ref) is in the process of running and `false` it is
not.

# See also
[`finished`](@ref)
"""
running(r::Runner) = LibSemigroups.running(_native(r))

"""
    timed_out(r::Runner) -> Bool

Check if the amount of time passed to [`run_for!`](@ref) has elapsed.

# See also
[`run_for!(::Runner, ::TimePeriod)`](@ref)
"""
timed_out(r::Runner) = LibSemigroups.timed_out(_native(r))

"""
    stopped(r::Runner) -> Bool

Check if the runner is stopped.

This function can be used to check whether or not [`run!`](@ref) has been
stopped for whatever reason. In other words, it checks if
[`timed_out`](@ref), [`finished`](@ref), or [`dead`](@ref).
"""
stopped(r::Runner) = LibSemigroups.stopped(_native(r))

"""
    dead(r::Runner) -> Bool

Check if the runner is dead.

This function can be used to check if we should terminate [`run!`](@ref)
because it has been killed by another thread.

# See also
[`kill!`](@ref)
"""
dead(r::Runner) = LibSemigroups.dead(_native(r))

"""
    stopped_by_predicate(r::Runner) -> Bool

Check if the runner was stopped, or should stop, because of
the argument last passed to [`run_until!`](@ref).

If `r` is running, then the nullary predicate is called and its
return value is returned. If `r` is not running, then `true` is
returned if and only if the last time `r` was running it was
stopped by a call to the nullary predicate passed to [`run_until!`](@ref).
"""
stopped_by_predicate(r::Runner) = LibSemigroups.stopped_by_predicate(_native(r))

"""
    running_for(r::Runner) -> Bool

Check if the runner is currently running for a particular length
of time.

If the Runner is currently running because its member function
[`run_for!`](@ref) has been invoked, then this function returns `true`.
Otherwise, `false` is returned.
"""
running_for(r::Runner) = LibSemigroups.running_for(_native(r))

"""
    running_for_how_long(r::Runner) -> Nanosecond

Return the duration of the most recent [`run_for!`](@ref) call as a
`Dates.Nanosecond` period.
"""
running_for_how_long(r::Runner) = Nanosecond(LibSemigroups.running_for_how_long(_native(r)))

"""
    running_until(r::Runner) -> Bool

Check if the runner is currently running until a nullary
predicate returns `true`.

If the Runner is currently running because its member function
[`run_until!`](@ref) has been invoked, then this function returns `true`.
Otherwise, `false` is returned.
"""
running_until(r::Runner) = LibSemigroups.running_until(_native(r))

"""
    current_state(r::Runner) -> RunnerState

Return the current state.

Returns the current state of the [`Runner`](@ref) as given by [`state`](@ref).
"""
current_state(r::Runner) = LibSemigroups.current_state(_native(r))

# ============================================================================
# Control
# ============================================================================

"""
    kill!(r::Runner)

Stop [`run!`](@ref) from running (thread-safe).

This function can be used to terminate [`run!`](@ref) from another thread.
After [`kill!`](@ref) has been called the Runner may no longer be in a valid
state, but will return `true` from [`dead`](@ref) .

# See also
[`finished`](@ref)
"""
kill!(r::Runner) = LibSemigroups.kill!(_native(r))

# ============================================================================
# Reporting
# ============================================================================

"""
    report_why_we_stopped(r::Runner)

Report why [`run!`](@ref) stopped.

Reports whether [`run!`](@ref) was stopped because it is [`finished`](@ref),
[`timed_out`](@ref), or [`dead`](@ref).
"""
report_why_we_stopped(r::Runner) = LibSemigroups.report_why_we_stopped(_native(r))

"""
    string_why_we_stopped(r::Runner) -> String

Return a human-readable string describing why the algorithm stopped.
"""
string_why_we_stopped(r::Runner) = LibSemigroups.string_why_we_stopped(_native(r))
