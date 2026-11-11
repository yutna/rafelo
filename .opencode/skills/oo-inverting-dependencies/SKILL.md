---
name: oo-inverting-dependencies
description: Use when domain code depends on a database, framework or clock, when an object builds or looks up its collaborators, or when wiring objects.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Inverting Dependencies

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Domain code should read like the clinic it serves. When a scheduler opens
a database connection or asks a global for the time, the rule it enforces
is tied to a machine, a product and a moment, and a test can run only
where those exist. This skill moves each outside system behind an
interface the domain owns, passes every collaborator in through a
constructor, and builds the whole graph once at the program's edge.

## When to use

- A domain class imports a database client, a network client, a clock or
  a framework type.
- A constructor creates its own collaborator, or a method fetches one
  from a global, a static field or a registry.
- A test cannot check a domain rule without a running database, a
  network or the real clock.
- A program has no single place where its objects are built and
  connected.
- A framework creates the program's objects, and domain classes carry
  its markers or extend its base classes.
- The same object is built in several places with slightly different
  collaborators.

## When not to use

- The dependency is a value or a stable library with no side effects,
  such as date arithmetic: depend on it directly.
- The question is which part of a design varies and deserves a seam at
  all:
  [encapsulating what varies](../oo-encapsulating-what-varies/SKILL.md)
  decides that from evidence.
- The question is how the whole system is split into layers or modules,
  not which collaborators one class receives.
- An object can exist half-built or needs setup calls after its
  constructor:
  [constructing valid objects](../oo-constructing-valid-objects/SKILL.md)
  covers that case.

## Core rules

1. Rule. **Put the interface the domain needs beside the domain, as a
   port, and let an adapter answer it.** The class that holds the rule
   names the messages it sends, such as `Appointments.add`, never the
   database type behind them. An adapter that talks to a database, a
   clock, a network or a framework answers those messages and keeps the
   outside details. The domain can then be built and exercised with no
   outside system running.

2. Rule. **Pass every collaborator to its object through the
   constructor.** A collaborator the object could be handed is not built
   inside it, fetched from a registry, or read from a static field. The
   parameter list then says what the object needs, a missing part stops
   the object at construction, and a test can supply a stand-in. A part
   whose lifetime the object owns, such as a schedule's slots, is still
   created by it.

3. Rule. **Construct and connect the object graph in one place at the
   program's edge: the composition root.** The entry script or the start
   of a request creates the adapters and gives them to the objects that
   use them. An adapter's name appears only in that root; no domain class
   constructs one.

4. Default. **Write the composition root by hand as plain constructor
   calls, each one after the objects it needs.** A missing collaborator
   then stops the program at start-up instead of during a booking, and
   the root reads as a map of the program.

   The exception is a framework that builds its own objects, such as
   request handlers. Give that framework the choices the root made, and
   keep its markers and base classes off domain classes.

5. Rule. **Do not hand a service locator or a container to domain
   code.** When a class asks a locator for its collaborators, the
   constructor no longer says what the class uses, the failure waits
   until a message runs, and each test must set up the locator before it
   can check a rule.

6. Judgement. **Take the port's shape from the domain's need, not from
   the outside library's own methods, and add the port only where the
   outside side varies, takes time, or is awkward to control in a test.**
   The outside side's behaviour decides: a database, a clock, a message
   queue or a mail server earns a port, while pure date arithmetic and
   other stable, side-effect-free libraries are called directly.

## Pattern

Before, `AppointmentScheduler` creates a `ClinicDatabase` in its
constructor and keeps the database type in its field. It cannot run
without a database, and no test can put a stand-in in its place. `book`
still sends `Appointment.book` to reserve the slot, so the domain rule
stays where it was.

Before:

```text
class ClinicDatabase
  + insert(appointment: Appointment): void

class AppointmentScheduler
  - database: ClinicDatabase
  + new()
    database := new ClinicDatabase()
  + book(slot: Slot, patient: PatientId): void
    appointment := Appointment.book(slot, patient)
    database.insert(appointment)
    return
```

`ClinicDatabase.insert` is taken to store one appointment once.

After:

```text
interface Appointments
  + add(appointment: Appointment): void

class DatabaseAppointments implements Appointments
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + add(appointment: Appointment): void
    database.insert(appointment)
    return

class AppointmentScheduler
  - appointments: Appointments
  + new(appointments: Appointments)
  + book(slot: Slot, patient: PatientId): void
    appointment := Appointment.book(slot, patient)
    appointments.add(appointment)
    return

class ClinicApp
  + static start(database: ClinicDatabase): AppointmentScheduler
    return new AppointmentScheduler(
      new DatabaseAppointments(database))
```

After, `AppointmentScheduler` holds the port and receives it through its
constructor. `DatabaseAppointments` adapts `ClinicDatabase` to that port,
and a call to `Appointments.add` is taken to store one appointment once.
`ClinicApp.start` is the composition root: it receives the open
database, builds the adapter once and the scheduler once, and is the
only place that names the adapter. The entry script opens the database
and passes it to `start`. `Appointment.book` is sent, not redeclared.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A domain class that imports a database, network, file or framework
  type.
- A constructor that creates its own collaborators with `new`.
- A static or global lookup for a collaborator inside a method.
- A test that needs a running database, a network or the real clock to
  check a domain rule.
- Object creation scattered across many classes instead of one root.
- A constructor that takes a locator or a container instead of the
  collaborators it uses.

## Common mistakes

- An interface for every class, including values and stable libraries
  with no side effects.
- A port that copies the outside library's methods, so the domain still
  speaks the library's terms.
- Passing the container itself into constructors, which is a service
  locator by another name.
- A composition root that also holds domain rules.
- Putting a framework's markers on domain classes so the framework can
  create them.
- Building the same object in two places, so the program has two graphs
  that drift apart.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-what-varies](../oo-encapsulating-what-varies/SKILL.md)
  decides whether a seam has evidence.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  keeps an object complete from its constructor, with every collaborator
  received.
- [oo-designing-interfaces](../oo-designing-interfaces/SKILL.md) shapes a
  port around the caller that sends it.

## Further reading

- [Ports and adapters](references/ports-and-adapters.md)
- [Composition roots](references/composition-roots.md)
