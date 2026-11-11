# Cycles and stability

## Finding a cycle

Write each module and the modules it depends on, one line per module:
the modules whose classes its field types, constructor parameters and
imports name. A cycle is a path that leaves a module and returns to it.
Walk the list from any module; when a module appears twice on one path,
the stretch between the two appearances is a cycle. A cycle through a
third module counts the same as a direct one, because the three cannot
be built or released apart either.

Take staff and scheduling. Staff's `LeaveRequests` holds
`Appointments`, so staff lists scheduling. Scheduling's `SlotOpener`
holds `Rota`, so scheduling lists staff. Each names the other, and the
path staff to scheduling to staff is a cycle. A module that appears on
no such path is on no cycle and needs no work.

## Three ways out

The first way is to move what both sides need into a module of its own.
Both old modules then depend on the new one, and neither depends on the
other. The cost is one more module, a name that belongs to neither
capability, and a place to put the classes that both sides change.

The second way is an interface the depending module owns, implemented
by the other module. The implementation's module depends on the
interface's module, so the arrow turns: staff owns `FreeDays`, and
scheduling's `AppointmentFreeDays` implements it over `Appointments`.
Staff no longer names scheduling, and scheduling depends on staff. The
cost is one more type and one line in the composition root, which hands
`LeaveRequests` an `AppointmentFreeDays`. This is the port of the
inverting dependencies skill, at module size.

The third way is an event the depended-on module publishes. The module
that used to be called reacts to the event instead, and the caller no
longer names it, so the remaining dependency points from the reacting
module to the event's type. The cost is that the reaction runs after
the change commits, its handler may receive the event twice, and the
caller cannot see the reaction's outcome. That is the trade the
publishing domain events skill describes.

## Abstractness beside instability

Abstractness is the share of a module's types that are interfaces or
abstract classes. Read it beside the instability of the diagnosing
coupling skill, rule 9. A module many others depend on has low
instability, and when it is also concrete it is hard to change: every
change reaches its dependants, and every dependant must rebuild. A
module that is both abstract and unstable has no dependants and little
implementation, so its types are unused and a reader cannot tell which
one to keep. A module that is stable and abstract holds the interfaces
its dependants use, and a module that is unstable and concrete holds
the implementations that change. The two readings together say which
of those a module is.

## The modular monolith

A modular monolith is one deployable unit with modules inside it. Each
module keeps its own public interface, its own classes and its own
data, and reaches another module only through that module's interface
or an event. The modules share one build, one release and one process,
so a call between them is a plain message with no network in between.
A change that must be true with a change in another module can still
happen in one transaction when the two modules share a store; one
aggregate per transaction stays the default, as rule 4 of designing
aggregates says.

The signs that one module should become a service are specific: it
must be deployed on a schedule of its own, it must be scaled on its own
load while the rest stays small, or another team must own it and
release it without the rest. The cost is real: each call across the
network can fail or slow, data in two services is no longer changed in
one transaction, and the new service needs its own build, deployment,
monitoring and on-call. When the need is smaller than that cost, keep
the module in the monolith and keep its boundary.
