---
name: oo-separating-reads-from-writes
description: Use when screens need data shaped unlike the model, when reads slow down writes, or when weighing read models, projections or event sourcing.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Separating Reads from Writes

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A change and a read ask for different things: a change protects a rule
and answers little, while a read serves a screen and answers a shape
that screen can show. This skill keeps the two apart at the level of the
use case, serves a screen from a plain read query while that is enough,
and gives a slow read or one over many tables a read model of its own.
The read model is a store of rows shaped for a screen, kept current by a
projection of the domain events, safe to receive an event twice and able
to rebuild itself, and it tells its readers how current it is. Event
sourcing is kept for an aggregate whose past states must be rebuilt and
whose events can be kept readable, and a second store only for reads the
write store cannot serve.

## When to use

- A screen needs data shaped unlike the domain model, such as a row
  joining several aggregates.
- Reads slow down writes, or a screen's query joins many aggregates on
  every refresh.
- You are weighing a read model, a projection or event sourcing.
- A screen must say how current the figures it shows are.
- You are deciding whether reads need a second store.
- An aggregate's past states must be rebuilt exactly.

## When not to use

- A screen shows a few fields of one aggregate and its query is plain:
  a read query is enough, as
  [layering the system](../oo-layering-the-system/SKILL.md) rule 6 says.
- The question is how a domain event is recorded, published or
  delivered: that is
  [publishing domain events](../oo-publishing-domain-events/SKILL.md).
- The question is keeping one aggregate's history of transitions for a
  report: that is
  [modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) rule 6.
- The module has no business rules and only moves data between a screen
  and a store.

## Core rules

1. Rule. **Keep a change and a read apart at the level of the use case: a
   use case that changes the clinic's state answers no more than what it
   created, such as the new appointment's identity, and a read changes
   nothing.** Command and query separation, the split
   [encapsulating state and
   behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
   rule 4 makes inside one object, here covers a whole use case, so each
   side can take the shape and the store it needs.

2. Default. **Serve each screen from a read query shaped for it, over
   the same store the domain writes, and go no further while that query
   stays plain and fast.** This is the light form that
   [layering the system](../oo-layering-the-system/SKILL.md) rule 6 and
   [designing repositories](../oo-designing-repositories/SKILL.md) rule 6
   already give; a query count that grows with the rows a screen shows is
   the finding [taming persistence](../oo-taming-persistence/SKILL.md)
   rule 6 checks.

   The exception is a read whose query joins many aggregates or slows
   the writes down: rule 3 gives it a read model of its own.

3. Rule. **Build a separate read model as a projection: a handler of the
   domain events that updates read rows shaped for one screen after each
   change commits, safe to receive an event twice, and able to rebuild
   its rows from scratch from the stored events or the write store.**
   Publishing domain events, rules 3 and 5, gives the handler the
   after-commit moment and the repeated-delivery safety it needs; where
   an event must not be lost, that skill's outbox keeps it until a relay
   has sent it. Nothing writes the read rows but the projection: a wrong
   row is fixed by fixing the write side or the projection and
   rebuilding.

4. Rule. **Tell the reader that a read model lags: a screen fed by a
   projection shows the state as of the last event it handled, so it
   says when it was last brought up to date, and a use case that must
   show its own change at once answers from the write side or from what
   the change returned.**

5. Judgement. **Store an aggregate as the list of its events, event
   sourcing, only when the business needs that history as the record of
   truth, such as an auditor rebuilding any past state of a care plan,
   and the team can keep every stored event readable for as long as it
   is kept; otherwise store the current state and keep the history the
   business asks for, as
   [modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) rule 6
   does.** What tips the balance is whether a past state must be rebuilt
   exactly, against the cost of keeping stored events readable for ever,
   a contract with future code under
   [crossing system boundaries](../oo-crossing-system-boundaries/SKILL.md)
   rule 6.

6. Judgement. **Give the read side a store of its own only when the reads
   need what the write store cannot give, such as a search across free
   text or a load the writes must not feel; keep one store while one
   serves both.** What tips the balance is the cost of running and
   keeping a second store current against the read load and the shapes
   the screens need.

## Pattern

Before, `TodayBoard` serves reception's board of the day's appointments
with their status by asking the clinic's database for a join on every
refresh. After, a projection keeps read rows shaped for the board, and
`TodayBoard` reads only those rows.

Before:

```text
class TodayBoard
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + rowsFor(date: Date): List<TodayBoardRow>
    return database.appointmentsJoined(date)
```

`ClinicDatabase` is the inverting dependencies skill's type.
`database.appointmentsJoined(date)` is taken to run one query joining
appointments, patients, clinicians and rooms on every read, against the
tables booking writes.

After:

```text
class TodayBoardProjection
  - updates: TodayBoardUpdates
  - handled: HandledEvents
  + new(updates: TodayBoardUpdates, handled: HandledEvents)
  + handle(id: EventId, event: AppointmentCancelled): void
    if handled.contains(id) then
      return
    else
      updates.markCancelled(event.appointment())
      handled.add(id)
    return

interface TodayBoardUpdates
  + markCancelled(appointment: AppointmentId): void

interface TodayBoardRows
  + forDate(date: Date): List<TodayBoardRow>

class TodayBoard
  - rows: TodayBoardRows
  + new(rows: TodayBoardRows)
  + rowsFor(date: Date): List<TodayBoardRow>
    return rows.forDate(date)
```

The read side holds only the read port and the projection only the
write port, as
[designing interfaces](../oo-designing-interfaces/SKILL.md) rule 2 asks,
and one adapter may implement both. `AppointmentCancelled`, `EventId`
and `HandledEvents` are the publishing domain events skill's, and the
handler form `handle(id, event)` is that skill's. `TodayBoardRow` is
taken to be a plain row shaped for the board. The projection records
only what the event states, that this appointment was cancelled, and
never marks its slot free, because that skill's `ReleaseSlot` frees the
slot later, in its own transaction. `HandledEvents` is per handler: the
projection holds its own, never `ReleaseSlot`'s, so the two never share
one. What is stored is one row marked cancelled and the event's
identity, in the read tables of the clinic's database, in the
projection's own transaction after the cancellation commits. The
handler for the event that booking records, which adds a row, is left
out of the fence. The fence also leaves out how the board reports when
it was last brought up to date, which rule 4 requires of the screen.

`TodayBoardProjection`'s constructor sets `updates` and `handled` before
`handle` reads them, and `TodayBoard`'s sets `rows` before `rowsFor`
reads it. For a new event, `handle` sends `updates.markCancelled` once,
marking the appointment's one row, and sends `add` once; for a repeated
one, it returns before either. No other step runs twice, and the fence
uses only keywords the notation defines.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A screen's query that joins many aggregates' tables on every refresh.
- A use case that changes state and also returns a screen's worth of
  data.
- Read rows written by anything other than their projection.
- A screen fed by a projection that never says how current it is.
- A proposal to store every aggregate as events, with no aggregate whose
  past states must be rebuilt.
- A projection that cannot be rebuilt from scratch.

## Common mistakes

- Building a separate read model for a screen a plain read query serves.
- Editing read rows by hand to fix a wrong figure.
- Reading a projection to decide a change, where the write side holds
  the current state.
- Adopting event sourcing for the whole system at once.
- Changing a stored event's shape with no plan for the events already
  stored.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  records and publishes the events a projection handles.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) lets a
  read with no decision take a read query.
- [oo-designing-repositories](../oo-designing-repositories/SKILL.md)
  gives the read query its shape and the domain its ports.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) keeps a
  history of transitions inside the aggregate.
- [oo-crossing-system-boundaries](../oo-crossing-system-boundaries/SKILL.md)
  treats a stored event as a contract with future code.

## Further reading

- [Projections](references/projections.md)
- [Event sourcing](references/event-sourcing.md)
