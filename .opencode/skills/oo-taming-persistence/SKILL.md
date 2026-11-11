---
name: oo-taming-persistence
description: Use when choosing active record or a data mapper, when a list fires one query per row, or when lazily loaded data fails outside its session.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Taming Persistence

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A domain model and a store drift apart unless one object owns the
translation between them. This skill chooses an active record while a
class still mirrors one table row, moves to a data mapper once the
class's fields or rules part from that row, and keeps every mapping
decision at the edge. It also keeps one object per identity within a
transaction, scopes the store's session to one use case, holds lazy
loads inside their aggregate and their transaction, and fills a list
with one read query whose count a test checks.

## When to use

- A module is choosing between an active record and a data mapper.
- A domain class extends the mapping tool's base class, carries its
  markers, or has a setter that only the mapping tool uses.
- A list screen or a report runs one query for each row it shows.
- Lazily loaded data is touched after the request's session has closed,
  or once for each item of a list.
- Two copies of one appointment are loaded in one use case.
- A store session is opened once and kept across requests.

## When not to use

- The question is what a repository offers, such as its query methods,
  specifications or query objects: that is
  [designing repositories](../oo-designing-repositories/SKILL.md).
- The question is which objects must change and be stored together in
  one transaction: that is
  [designing aggregates](../oo-designing-aggregates/SKILL.md).
- The store holds nothing the domain model rebuilds, such as an
  append-only log or a cache of computed figures.
- The question is giving reads a separate model of their own, kept
  current from the changes: that is
  [separating reads from writes](../oo-separating-reads-from-writes/SKILL.md),
  which builds it as a projection of the changes.

## Core rules

1. Judgement. **Choose an active record, an object that is one table
   row and saves itself, while a module's classes mirror its tables and
   hold few rules, and a data mapper, a separate object that moves data
   between domain objects and the store, once a class's fields or rules
   part from its table.** [Placing domain
   logic](../oo-placing-domain-logic/SKILL.md) rule 1 decides how a
   module organises its logic, and this choice follows it: transaction
   scripts sit well on active records, while a domain model needs a
   mapper. What tips the balance is whether each class still matches one
   table row and holds no rule that spans rows.

2. Rule. **With a data mapper, keep every mapping decision in the
   adapter: table and column names, the stored row's shape, and how an
   aggregate is rebuilt.** Give the mapper nothing the domain would not
   give any caller: no public setter and no public constructor added for
   it. Where the mapper cannot rebuild through the class's own factory,
   as [designing repositories](../oo-designing-repositories/SKILL.md)
   rule 2 asks, map into a separate stored record and convert it in the
   adapter, and keep the mapping tool's markers off domain classes, the
   way the exception to
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rule
   4 keeps a framework's markers off them.

3. Rule. **Within one transaction, answer one object for one identity:
   the identity map of the store's session, or the repository itself,
   returns the object it already loaded rather than a second copy.** An
   identity map is the session's record of the object it loaded for each
   identity. Two copies of one appointment in one use case each take a
   change, and whichever is saved last silently drops the other's.

4. Rule. **Begin and end a unit of work, the session that tracks the
   objects it loaded and writes their changes at commit, exactly where
   the application service opens and ends the transaction
   ([placing domain logic](../oo-placing-domain-logic/SKILL.md) rule 2):
   one unit of work per use case.** A session kept across requests
   answers objects other users have since changed, and writes changes
   nobody meant to save. Whether changes reach the store by tracking or
   by an explicit save stays
   [designing repositories](../oo-designing-repositories/SKILL.md) rule
   5.

5. Rule. **Let no lazy load cross an aggregate's boundary or outlive
   its transaction: load each aggregate whole ([designing
   repositories](../oo-designing-repositories/SKILL.md) rule 6) and
   reach another aggregate by its identity through its own repository
   ([designing aggregates](../oo-designing-aggregates/SKILL.md) rule 3).**
   Lazy loading loads an association when it is first touched, not with
   its aggregate, so a lazy reference runs a query at that moment, which
   may be in a screen after the session has closed, where it fails, or
   once for each item of a list.

6. Default. **Fill a list with one read query that returns the rows it
   shows, rather than loading aggregates and touching their
   associations one by one, and assert in a test how many queries the
   use case runs.** A query per row is one read for each item, so the
   count grows with the list, and a test that counts queries finds it
   before a busy clinic day does. The read query is the one
   [layering the system](../oo-layering-the-system/SKILL.md) rule 6
   lets a decision-free read use.

   The exception is a list whose length cannot grow, such as one
   clinician's breaks in a day: a query per item costs a fixed few.

## Pattern

Before, the active record `Appointment` is one table row that saves
itself, and `CompleteAppointment` asks it for a status change that
writes the row at once. After, `Appointment` is a domain object with no
knowledge of its row, `Appointments` is the port that finds and saves
it, and `MappedAppointments` keeps the store's session behind that port.

Before:

```text
class Appointment extends StoredRecord
  - status: AppointmentStatus
  + static findById(id: AppointmentId): Appointment
  + changeStatus(next: AppointmentStatus): void
    status := next
    save()

class CompleteAppointment
  + run(id: AppointmentId): void
    appointment := Appointment.findById(id)
    appointment.changeStatus(Completed)
    return
```

`findById` is taken to read the row stored under an `AppointmentId`
and build the appointment, and `save()` is the message `StoredRecord`
answers, so `changeStatus` writes that appointment's row, in the
clinic's database, at once, outside any transaction a use case opened.
`AppointmentStatus` is the
[modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) skill's
four-member enumeration, and `Completed` is one of its members. The
fence shows only the status field, because the row's other columns play
no part here. Any caller can send `changeStatus` any status, so the
appointment never refuses a move its lifecycle forbids.

After:

```text
class Appointment
  - id: AppointmentId
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(id: AppointmentId, slot: Slot, patient: PatientId,
      status: AppointmentStatus)
  + static book(id: AppointmentId, slot: Slot,
      patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(id, slot, patient, Scheduled)
  + static restore(id: AppointmentId, slot: Slot, patient: PatientId,
      status: AppointmentStatus): Appointment
    return new Appointment(id, slot, patient, status)
  + id(): AppointmentId
    return id
  + complete(): void
    raises AppointmentNotCompletable
    if status = InProgress then
      status := Completed
    else
      raise AppointmentNotCompletable
    return

interface Appointments
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
  + save(appointment: Appointment): void

class MappedAppointments implements Appointments
  - session: StoreSession
  + new(session: StoreSession)
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
    return session.load(id)
  + save(appointment: Appointment): void
    session.store(appointment)
    return

class CompleteAppointment
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(id: AppointmentId): void
    appointment := appointments.find(id)
    appointment.complete()
    appointments.save(appointment)
    return
```

`Appointment` keeps the
[designing repositories](../oo-designing-repositories/SKILL.md) skill's
shape, which adds `- id: AppointmentId` first, a private constructor
that takes it, `book`, `restore` and `id()`; `notation.md`'s sketch
leaves that field out. `complete()` is the
[modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) skill's
transition: it raises `AppointmentNotCompletable` unless the status is
`InProgress`, and otherwise sets it to `Completed`. The appointment
extends nothing.

`interface Appointments` offers `find`, which raises
`AppointmentNotFound`, and `save`; it leaves out the port's `add` and
`forClinicianOn`, which this use case never sends. `MappedAppointments`
holds a `StoreSession` set by its constructor: `find` returns
`session.load(id)` and `save` sends `session.store(appointment)`.
`CompleteAppointment` holds the port set by its constructor and sends
`find`, `complete()` and `save`, once each.

`StoredRecord` and `StoreSession` stand for any mapping tool's own
types, and this skill names no mapping tool. `session.load(id)` is taken
to rebuild the appointment from its row through `Appointment.restore`,
to answer the same object again for the same identity within the
session, and to raise `AppointmentNotFound` when no row has that
identity. `session.store` is taken to write the whole appointment at
commit. What is stored is the completed appointment, under its
`AppointmentId`, in the clinic's database, in the transaction `run`
opens, with the session opened and closed with it; the fence leaves
both boundaries out.

Each version changes the status once and stores it once: the Before
version through `changeStatus` and `save()`, the After version through
`complete()` and `appointments.save`.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A domain class that extends the mapping tool's base class, or carries
  its markers.
- A public setter or a public no-argument constructor that exists only
  for the mapping tool.
- A list screen or a report whose query count grows with its rows.
- An association loaded on first touch that crosses to another
  aggregate.
- A store session kept open across requests or screens.
- Two objects for one identity in one use case.

## Common mistakes

- Adopting a data mapper for a module of a few independent rules that
  mirror their tables.
- Turning on eager loading everywhere to cure a query per row.
- Letting a template or a view touch an association the use case did
  not load.
- Saving an object in the middle of a use case, before its transaction
  ends.
- Counting queries in a test against the in-memory store of
  [designing repositories](../oo-designing-repositories/SKILL.md): it
  checks the rules but runs no query, so the count test runs against the
  mapping tool and a real store.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-designing-repositories](../oo-designing-repositories/SKILL.md)
  gives each aggregate a port that speaks in domain types and keeps the
  store behind it.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) draws
  the boundary a lazy load must not cross.
- [oo-placing-domain-logic](../oo-placing-domain-logic/SKILL.md) gives
  the use case its transaction and keeps each rule in the domain.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) lets a
  decision-free read take a read query at the edge.

## Further reading

- [Identity and units of work](references/identity-and-units-of-work.md)
- [Loading and query counts](references/loading-and-query-counts.md)
