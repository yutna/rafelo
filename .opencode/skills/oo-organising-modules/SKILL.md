---
name: oo-organising-modules
description: Use when grouping classes into packages, when packages depend on each other in a cycle, or choosing between a modular monolith and services.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Organising Modules

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A module is a group of classes with one public interface; a package or
a folder is how the code spells it. How a codebase is divided into
modules decides how much of it one change touches, what can be built
and tested apart, and how many teams must agree before a release. This
skill groups classes by business capability, keeps the dependencies
between modules free of cycles, makes a module that many others depend
on abstract, gives every module a small public interface the build
enforces, and keeps one deployable unit until a module must live apart.
Scheduling, billing and clinical records are capabilities of the
clinic, and the layers of each sit inside its module.

## When to use

- You are deciding how to group classes into packages or folders.
- Two modules import each other, directly or through a third.
- A module many others depend on changes in most releases.
- One module uses a class or a table that belongs to another.
- You are choosing between one deployable unit and separate services.
- The build has no check on which module may depend on which.

## When not to use

- The question is how tightly two parts are tied, or how to measure
  it: that is
  [diagnosing coupling](../oo-diagnosing-coupling/SKILL.md).
- The question is the layers inside one module and which way they
  depend: that is
  [layering the system](../oo-layering-the-system/SKILL.md).
- The question is where one team's model ends and another's begins:
  that is
  [bounding contexts](../oo-bounding-contexts/SKILL.md).
- The code is one small module with one capability and one team.
  Leave it as it is.

## Core rules

1. Default. **Make the top-level modules business capabilities, such as
   scheduling, billing and clinical records, not technical kinds such
   as controllers, services and repositories.** The layers of each
   capability then sit inside its module, so a change to one capability
   touches one module.

   The exception is a small application with one capability, where one
   module with a folder per layer is enough.

2. Rule. **Put classes that change for the same reason and are used
   together in one module, and keep apart classes that are not used
   together.** A module that bundles unrelated classes makes every user
   depend on, rebuild and retest all of them for a change to one. A
   capability spread over several modules makes one change touch them
   all.

3. Judgement. **Weigh three pulls on a module's contents: classes that
   change together, classes that are used together, and classes
   released together under one version for others to reuse.** Early in
   a project, group for change. Once other teams reuse a module through
   its releases, group for reuse and release it as a unit. What tips
   the balance is whether others depend on the module through versioned
   releases.

4. Rule. **Keep the module dependency graph free of cycles.** A cycle
   makes its modules one module in practice: none can be built, tested
   or released without the others. Break it by moving what both sides
   need into a module of its own, by an interface the depending module
   owns and the other implements, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rule 1 asks, or by an event the depended-on module publishes, as
   [publishing domain events](../oo-publishing-domain-events/SKILL.md)
   describes.

5. Default. **Make a module that many others depend on abstract in
   proportion to how many depend on it: it holds the interfaces and
   values the others use, while the implementations that change live in
   modules that depend on it.** Read the counts and the direction of
   stability in
   [diagnosing coupling](../oo-diagnosing-coupling/SKILL.md), rules 9
   and 10.

   The exception is a stable module of concrete values that rarely
   change, such as dates, times and money: it may stay concrete.

6. Rule. **Give each module a small public interface and keep the rest
   internal: other modules use only what it publishes, never its
   internal classes or its tables, and a check in the build fails on a
   dependency the module does not allow.** A boundary that only a
   convention guards wears away under the first deadline.

7. Judgement. **Build a modular monolith first: modules with their own
   public interfaces and their own data inside one deployable unit.
   Split a module into a separate service only when it must be
   deployed, scaled or owned apart.** What tips the balance is whether
   that need outweighs the cost of calls across a network, of data no
   longer changed in one transaction, and of running another service.

## Pattern

Before, `LeaveRequests` in the staff module asks scheduling's
`Appointments` port whether a clinician is free, and `SlotOpener` in
the scheduling module asks staff's `Rota` whether the clinician is on
duty. Each module's field types name a type in the other, so the two
depend on each other.
`Appointments.forClinicianOn(clinician, date)` is the query
[designing repositories](../oo-designing-repositories/SKILL.md) gives
its store, and `Slot.startingAt` is the notation's factory.

Before:

```text
-- module staff
class LeaveRequests
  - appointments: Appointments
  + new(appointments: Appointments)
  + canTakeLeave(clinician: ClinicianId, date: Date): Boolean
    return appointments.forClinicianOn(clinician, date).isEmpty()

class Rota
  + isOnDuty(clinician: ClinicianId, startsAt: DateTime): Boolean

-- module scheduling
class SlotOpener
  - rota: Rota
  + new(rota: Rota)
  + open(clinician: ClinicianId, startsAt: DateTime): Slot
    raises ClinicianOffDuty
    if rota.isOnDuty(clinician, startsAt) then
      return Slot.startingAt(clinician, startsAt)
    else
      raise ClinicianOffDuty
```

The field types create two module dependencies: staff depends on
scheduling through `Appointments`, and scheduling depends on staff
through `Rota`. `isEmpty()` is taken to be true when the list holds no
item, `Boolean` is the yes-or-no type, and the fences change and store
nothing. Each `canTakeLeave` sends one query; in the Before it is
`forClinicianOn`.

After, the staff module declares `FreeDays` and depends on nothing in
scheduling. Scheduling's `AppointmentFreeDays` implements that
interface over its own `Appointments` port, so scheduling depends on
staff, and the composition root hands `LeaveRequests` an
`AppointmentFreeDays`.

After:

```text
-- module staff
interface FreeDays
  + isFreeOn(clinician: ClinicianId, date: Date): Boolean

class LeaveRequests
  - freeDays: FreeDays
  + new(freeDays: FreeDays)
  + canTakeLeave(clinician: ClinicianId, date: Date): Boolean
    return freeDays.isFreeOn(clinician, date)

class Rota
  + isOnDuty(clinician: ClinicianId, startsAt: DateTime): Boolean

-- module scheduling
class AppointmentFreeDays implements FreeDays
  - appointments: Appointments
  + new(appointments: Appointments)
  + isFreeOn(clinician: ClinicianId, date: Date): Boolean
    return appointments.forClinicianOn(clinician, date).isEmpty()

class SlotOpener
  - rota: Rota
  + new(rota: Rota)
  + open(clinician: ClinicianId, startsAt: DateTime): Slot
    raises ClinicianOffDuty
    if rota.isOnDuty(clinician, startsAt) then
      return Slot.startingAt(clinician, startsAt)
    else
      raise ClinicianOffDuty
```

The field types create one module dependency: scheduling depends on
staff through `FreeDays`, and staff names nothing in scheduling. Each
`canTakeLeave` still sends one query; in the After it is `isFreeOn`,
which sends `forClinicianOn` once. `Rota` and `SlotOpener` are
unchanged, so the cycle is broken by the interface and the class that
implements it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- Top-level folders named for technical kinds, such as controllers,
  services and repositories, in an application with several business
  areas.
- Two modules that import each other, directly or through a third.
- A module that most others depend on and that changes in most
  releases.
- A class in one module that uses another module's internal class or
  table.
- A module boundary that no build check enforces.
- A plan to split into services in order to fix a dependency tangle.

## Common mistakes

- Splitting into separate services before the modules have clean
  boundaries inside one deployable unit.
- Breaking a cycle by merging the two modules into one large module.
- A shared module that collects whatever two other modules both need.
- Grouping classes by what they are, such as all entities together,
  rather than by what changes together.
- Publishing a whole module because one of its classes is needed
  elsewhere.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-diagnosing-coupling](../oo-diagnosing-coupling/SKILL.md) measures
  how many modules depend on a module and how unstable it is.
- [oo-hiding-implementation](../oo-hiding-implementation/SKILL.md)
  keeps a module's decisions behind a small interface.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts an interface in the module that sends it and the implementation
  in the module that answers.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  publishes a change for another module to react to.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) decides
  the layers inside a module and which way they depend.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) draws where
  one team's model ends; one context may hold several modules.

## Further reading

- [Grouping classes](references/grouping-classes.md)
- [Cycles and stability](references/cycles-and-stability.md)
