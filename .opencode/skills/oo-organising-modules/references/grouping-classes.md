# Grouping classes

- [The three pulls](#the-three-pulls)
- [How a module drifts](#how-a-module-drifts)
- [One app, two arrangements](#one-app-two-arrangements)
- [The public interface](#the-public-interface)
- [A build check](#a-build-check)

A module is a group of classes that share one public interface. What
belongs inside it is decided by three pulls, and they rarely agree. The
work is to see which one the code and the team need now, and to move
when the answer changes.

## The three pulls

|Pull|Example|Cost of ignoring it|
|---|---|---|
|Change together|A new rule for opening a slot|One change edits two modules|
|Used together|Booking an appointment|Booking rebuilds a report it never uses|
|Released together|A reused appointment finder|Callers cannot match versions|

Classes that change together belong together because one request edits
both. A rule about who may open a slot sits beside the slot it opens,
not in a module for forms. When those classes part, one request opens
two modules, and every reviewer must know both.

Classes that are used together belong together because one job sends
messages to both, and a class that job never uses belongs elsewhere.
Booking an appointment reserves a slot and stores the appointment, so
`Slot` and the `Appointments` port serve one job and share a module.
Last month's no-show report reads appointments, but booking never
calls it, so it sits in a module of its own. When the report shares
booking's module, every change to the report makes booking depend on,
rebuild and retest a class it never uses.

Classes released together belong together because other teams take them as one
version. A module another team reuses through versioned releases is a product:
its classes share a version, a change log and a promise not to break callers.
When the classes part, a consumer reusing them as one unit gets separate
versions, or none. It cannot tell which versions work together, so it must
upgrade them in step, and a release of one half can break the other.

## How a module drifts

Early in a project, group for change: the team is still finding the
capability's shape, and classes that change in one commit should sit
together. A module that starts as one capability then gains a class
another team wants to reuse. The pull toward reuse and release grows,
and the module's version becomes a promise to that team. Later, a
second capability asks for one class from it. Adding a method for that
caller pulls the module toward use, and the module now serves two
masters.

The drift is not a mistake by itself. It becomes one when nobody
decides: the module holds classes from two capabilities, changes for
two reasons, and is released on a schedule that suits neither. Read the
change history, see which classes change in the same commits, and move
the classes that no longer share a reason.

## One app, two arrangements

The same clinic application can be laid out by technical kind:

- `controllers`
- `services`
- `repositories`
- `jobs`

Or by business capability:

- `scheduling`
- `billing`
- `clinical-records`
- `staff`

In the first arrangement a change to who may open a slot edits a
controller, a service and a repository, and each folder holds classes
from every capability. In the second, the same change opens the
`scheduling` folder alone, and that folder holds its own controller,
use cases, domain classes and store adapter. Each capability keeps the
layers it needs, and the layers are the ones the layering skill draws.

## The public interface

Each module publishes one small interface. It holds the messages other
modules send, such as `Rota.isOnDuty`, the interfaces they implement,
such as `FreeDays`, and the values they pass, such as `ClinicianId`. It
also holds the events other modules react to. Everything else stays
internal: the appointment, the use case that books it, the store adapter
and the table the adapter writes. Another module never names an internal
class, a table or a row.

The interface is small when a reader can hold it in mind, and when a
new public method must replace an old one rather than join it. An
internal class can change or disappear without a caller noticing, so
the module can keep its secret and revise it.

## A build check

The build check lists each module's allowed dependencies. For each
module the list names the modules it may import, and nothing else. A
new import that is not on the list fails the build, and the author
either removes it or adds it after the owning teams agree. The list
sits beside the build file so a reviewer sees the same rule.

A check that is skipped, warns, or lives in a wiki is a convention. The
build check is the one that keeps the boundary honest, because it fails
before a change reaches the main branch.
