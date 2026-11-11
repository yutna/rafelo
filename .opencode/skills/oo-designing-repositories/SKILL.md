---
name: oo-designing-repositories
description: Use when designing a repository, when it grows a find method per screen, returns rows instead of objects, or updates single fields.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Repositories

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A repository is where the domain finds and stores its aggregates. It
should read like a collection of whole aggregates, speak in the domain's
types, and keep every storage detail on the outside. When it grows a
method per screen, answers with rows, or writes one field by identity,
it has stopped being a collection and become a window onto a table. This
skill gives each aggregate root one repository, names its queries for
the questions the clinic asks, and chooses how a change reaches the
store. The aim is domain code that can be read, tested and changed
without knowing where its objects live.

## When to use

- A repository has grown a method per screen or report.
- A repository answers with rows, maps or partial records instead of
  whole aggregates.
- A caller changes one field by identity, such as a status.
- You are deciding where a new aggregate is loaded from and saved to.
- A search's criteria combine freely, and each caller builds its own
  query.
- A domain class holds a connection, query text or a storage marking.

## When not to use

- The object is not an aggregate root: an inner entity, a value, or a
  plain record a report reads.
- The code is a report or an export that reads rows and changes
  nothing. A plain query that returns data serves it, and no aggregate
  is loaded.
- The question is how domain code reaches any outside service through a
  port and an adapter wired at the composition root, not how aggregates
  are stored and found. That is
  [inverting dependencies](../oo-inverting-dependencies/SKILL.md).

## Core rules

1. Rule. **Give each aggregate root one repository that reads like a
   collection of whole aggregates: `add` a new one, `find` one by its
   identity, `remove` one, and nothing that hands out an inner part.**
   Name it for what it holds, such as `Appointments`; a name with
   Repository in it is fine where callers need to know they are asking a
   store, as
   [naming classes and methods](../oo-naming-classes-and-methods/SKILL.md)
   allows. An inner entity has no repository of its own.

2. Rule. **Declare the repository's interface in the domain, in the
   domain's types only, and implement it at the edge: no connection,
   row, query text or storage session crosses the interface, and no
   domain class knows how it is stored.** The interface and its
   implementation are the port and the adapter of
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md), and
   the implementation rebuilds each aggregate through a factory of its
   class, such as the notation's `Appointment.restore`, so no field is
   set from outside the class.

3. Default. **Name each query for the question the domain asks, such as
   `forClinicianOn(clinician, date)`, and return whole aggregates, not a
   general `findBy(field, value)` or a query builder handed to
   callers.** A name says which clinic question it answers, so a reader
   knows what comes back without opening the implementation.

   The exception is a search whose criteria combine freely, such as a
   reception search by any mix of clinician, date range and kind of
   appointment. Rule 4 gives that search a shape.

4. Judgement. **Give a query a specification or a query object when the
   named methods multiply.** A specification is a domain object that
   answers whether one aggregate meets a rule, so the same rule checks
   one aggregate and, translated by the implementation, selects many. A
   query object carries a search's criteria to the repository, which
   turns them into the store's query. What tips the balance is how many
   query methods the repository has grown, and whether one rule is
   needed both to check one object and to select many.

5. Judgement. **Choose how changes reach the store: a repository that
   keeps track of the aggregates it handed out and stores their changes
   when the transaction ends, or one with an explicit `save(aggregate)`
   that the caller sends after each change.** What tips the balance is
   whether the storage code beneath the repository tracks changes for
   you; without that, an explicit `save` is plain and easy to test.
   Either way, the application service that opens the transaction
   decides when it ends, not the repository.

6. Rule. **Change an aggregate only by loading it whole, sending its
   root the change and storing it whole: no `updateStatus(id, status)`
   or other method that writes one field behind the root.** That is rule
   2 of [designing aggregates](../oo-designing-aggregates/SKILL.md). A
   screen that needs a few fields of many aggregates reads them through
   a separate read query that returns plain data, not through the
   repository.

## Pattern

Before, `FinishConsultation` asks a data-access object to overwrite a
status. The appointment's own rule never runs, so an appointment that
never started can be marked completed. After, the use case asks the
store for the appointment, sends it `complete()` and saves it.

Before:

```text
class AppointmentDao
  - connection: DatabaseConnection
  + new(connection: DatabaseConnection)
  + findByClinicianIdAndDate(clinicianId: String,
      date: String): List<AppointmentRow>
    return connection.query(
      "appointments of one clinician on one day",
      clinicianId, date)
  + updateStatus(id: String, status: String): void
    connection.execute(
      "the status of one appointment by its id", status, id)
    return

class FinishConsultation
  - dao: AppointmentDao
  + new(dao: AppointmentDao)
  + run(id: String): void
    dao.updateStatus(id, "completed")
    return
```

`connection.query(text, ...)` is taken to run one read query and answer
its rows, `connection.execute(text, ...)` to run one write statement
once, and the text is a string literal that says what the call asks,
with the values sent beside it as arguments; the store's own query
language stays outside this skill. `AppointmentRow` is taken to be the
store's row, not an appointment. `findByClinicianIdAndDate` answers rows
for one clinician and one day, and `updateStatus` writes one status by
id, so a caller decides the appointment's next state.
`FinishConsultation.run` sends `"completed"` for any id, so an
appointment that never started is marked completed and the appointment's
own rule never runs. `"completed"` is the status text the table stores.
What `updateStatus` stores is one status column, in the store the
connection reaches, in the transaction `FinishConsultation.run` opens
and ends; the fence leaves those boundaries out.

After:

```text
interface Appointments
  + add(appointment: Appointment): void
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
  + forClinicianOn(clinician: ClinicianId, date: Date): List<Appointment>
  + save(appointment: Appointment): void

class FinishConsultation
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(id: AppointmentId): void
    appointment := appointments.find(id)
    appointment.complete()
    appointments.save(appointment)
    return
```

The port is
[inverting dependencies](../oo-inverting-dependencies/SKILL.md)'s
`Appointments`, which declares `add`, and
[modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) adds `due` to
it; this fence shows the `add` it keeps and the three methods this skill
adds, `find`, `forClinicianOn` and `save`, and leaves `due` as that
skill writes it. A store named `AppointmentRepository` plays the same
role, and `find` keeps the name
[deciding object or data](../oo-deciding-object-or-data/SKILL.md) sends
to its `AppointmentRepository`. The store finds and saves an appointment
by the `AppointmentId` it carries, which `notation.md`'s sketch of
`Appointment` leaves out. The example takes the explicit `save` of
rule 5, so `FinishConsultation.run` opens the transaction and ends it
once `save` has written the appointment; the fence leaves those
boundaries out. What is stored is the whole appointment, in the
`Appointments` store, in that transaction. `complete()` is the
lifecycles skill's transition, and it refuses an appointment that is
not in progress, so the appointment's own rule runs. The change touches
the appointment alone: no other aggregate is read or saved.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A repository method per screen or report, each named for a list of
  fields.
- A repository that returns rows, maps or partial records instead of
  aggregates.
- A method that writes one field by identity, such as
  `updateStatus(id, status)`.
- A repository for an inner entity of an aggregate.
- Query text, a connection or a storage session in a domain class.
- A repository that commits its own transaction inside each call.

## Common mistakes

- Copying a table's columns into the repository's method names.
- Handing callers a general query builder in the name of flexibility.
- Saving part of an aggregate to make one screen faster.
- Giving a domain class storage markings or a base class from the
  storage library.
- Testing the domain only against the real database, because the
  repository has no in-memory implementation.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  gives the domain a port and puts its adapter at the edge.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) draws
  the boundary a repository keeps whole.
- [oo-hiding-implementation](../oo-hiding-implementation/SKILL.md)
  keeps the store's own types and errors from reaching a caller.
- [oo-taming-persistence](../oo-taming-persistence/SKILL.md) keeps the
  mapping tool's sessions, identity map and loading in check behind the
  repository.

## Further reading

- [Specifications and query objects](references/specifications-and-query-objects.md)
- [Persistence ignorance](references/persistence-ignorance.md)
