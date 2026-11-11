# Event sourcing

A care plan can be stored as the list of its events: the plan approved, a
therapy session booked, that session attended, a review added. Its
current state is rebuilt by applying those events in order, from the
oldest. Event sourcing is that storage: the events are the record of
truth, and the current state is what reading them gives.

## What it gives and what it costs

An event-sourced care plan can be rebuilt as it stood after any event.
An auditor reading the list sees what happened and in which order, not a
summary written later, and a dispute about a past state is settled from
the same record. Those are the reasons to choose it.

The cost starts with keeping every stored event readable for as long as
it is stored. A change to an event's shape is a change to a contract
with future code, which
[crossing system boundaries](../../oo-crossing-system-boundaries/SKILL.md)
rule 6 covers, so it needs a planned migration or a new version. The
cost continues each time a state is rebuilt: replaying a long list is
slow, so a snapshot, a stored copy of the plan's state at one event,
lets a rebuild start there and apply only the later events. A snapshot
is an optimisation and never the record of truth, because the events
still answer any past state.

Every read model fed by the plan's events is rebuilt from those events
too. No stored current-state row is the record of truth, so a new
projection, or an old one whose shape changed, replays the list on its
own.

## When the current state is enough

When the business asks only when and why a plan's state changed, the
current state with a list of past transitions is enough, as
[modeling lifecycles](../../oo-modeling-lifecycles/SKILL.md) rule 6 keeps
it. The list answers the report, the current state answers the next
change, and the plan does not carry the cost of a replay.

The choice is made for one aggregate at a time, never for the whole
system at once. A care plan may be event sourced while appointments and
invoices keep their current state, and each aggregate is judged by
whether its own past states must be rebuilt exactly.
