---
name: oo-publishing-domain-events
description: Use when other parts react after a change is saved, when a use case grows a step per reaction, or a message goes out before the change commits.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Publishing Domain Events

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

One change often sets other parts of the clinic in motion. A cancelled
appointment frees a slot for the waiting list and calls for a letter; a
completed visit calls for an invoice. This skill names such a change as
a past-tense event, records it inside the aggregate that makes the
change, publishes it only after the transaction commits, and runs each
reaction as its own handler in a transaction of its own. An event that
must not be lost is stored with the change in an outbox, and every
handler is safe to receive it twice. Where the caller needs the
reaction's outcome to finish, the skill keeps a direct message instead.

## When to use

- A letter, a notice, an invoice or another part must follow a change
  once it is saved.
- One use case grows a step for each new reaction to the same change.
- A message leaves before the transaction commits, so a rollback leaves
  a letter about a change that never happened.
- A reaction may fail while the change must stay saved.
- An event must reach another process, or must not be lost when one
  stops.
- A handler runs twice for one event and changes something twice.

## When not to use

- The reaction must be true at the same moment as the change, by a rule
  that covers both objects: those objects belong in one aggregate
  (designing aggregates, rule 1).
- The caller needs the reaction's outcome to finish, such as booking,
  which reserves the slot before the appointment exists.
- The question is storing an aggregate as the list of its past events,
  or building read-only views from events: that is
  [separating reads from writes](../oo-separating-reads-from-writes/SKILL.md).
- The question is the shape or the version of a message that another
  organisation's system reads.

## Core rules

1. Rule. **Name a domain event for a change in the clinic that other
   parts react to, in the past tense and in the staff's words, and make
   it a value that carries the identities and the facts its handlers
   need.** A cancellation becomes `AppointmentCancelled`, which holds
   the appointment, the slot, the patient and the reason. An event is
   not a command: `SendCancellationLetter` asks for an action, while the
   event says what happened. Nor is it a copy of the whole aggregate,
   which would tie every handler to the aggregate's fields. The words
   come from speaking the domain language, not from a database column.

2. Rule. **Record the event inside the aggregate method that makes the
   change, and let the aggregate hand out the events it has recorded.**
   A domain object never calls a handler, a message bus or a broker.
   `Appointment.cancel` records `AppointmentCancelled` in the branch
   that changes the status, so the event exists exactly when the change
   happens, and a test of `cancel` reads the recorded events with
   nothing else running.

3. Rule. **Publish an event only after the transaction that recorded it
   commits, and run each handler's change in a transaction of its own.**
   A handler that runs before the commit can act on a change that then
   rolls back, such as a letter about a cancellation that never
   happened; a handler that joins the first transaction changes two
   aggregates in it. This is the later step of designing aggregates,
   rule 4: until the handler runs, the other aggregate is behind, and
   the reply to the user says what has happened, not what will.

4. Default. **When an event must reach another process, or must not be
   lost, store it in an outbox: the transaction that stores the change
   also stores the event, in the same database, and a relay outside that
   transaction sends each stored event and then marks it sent.**

   The exception is an event whose loss costs nothing, such as a hint
   that a screen may refresh: it may be sent after the commit with no
   outbox.

5. Rule. **Make each handler safe to receive the same event twice:
   before it changes anything, it checks whether it has already handled
   that event, by the identity the outbox gave the event or by the state
   of what it changes.** A relay that stops after sending and before
   marking sends the event again, so delivery is at least once, never
   exactly once.

6. Judgement. **Choose an event when the change is complete without its
   reactions and the reactions vary or belong to other modules; choose a
   direct message when the caller needs the outcome to finish its own
   work.** Cancelling an appointment is complete before the letter goes
   out, so the letter is a handler; booking needs the slot reserved
   before the appointment exists, so it sends the slot a message inside
   one transaction, the exception of designing aggregates, rule 4. What
   tips the balance is whether the use case is done while the reaction
   has not yet run, and how many parts react: one reaction in the same
   module that must happen at once stays a direct message, because an
   event makes the flow harder to follow.

## Pattern

Before, `CancelAppointment` changes the appointment, releases its slot,
stores both and sends the letter inside one transaction. After, the
appointment records what happened, the use case stores the event with
the change, and each handler runs after the commit in a transaction of
its own.

Before:

```text
class CancelAppointment
  - appointments: Appointments
  - slots: Slots
  - letters: Letters
  + new(appointments: Appointments, slots: Slots, letters: Letters)
  + run(id: AppointmentId, reason: CancellationReason): void
    appointment := appointments.find(id)
    appointment.cancel(reason)
    slot := slots.find(appointment.slot())
    slot.release(appointment.patient())
    letters.sendCancellation(id, reason)
    slots.save(slot)
    appointments.save(appointment)
    return
```

The Before's `Appointment` is the After's class without `events` and
`recordedEvents`. `CancelAppointment` carries the name the assigning
responsibilities skill gives this use case; that fence passes the whole
appointment and shows the delegation, while this one takes the appointment's
identity and the ports it calls, because it opens the transaction and stores the
change. `CancelAppointment.run` changes two aggregates in one transaction:
`appointments.save` stores the changed appointment under its `AppointmentId` and
`slots.save` stores the changed slot under its `SlotId`, both in the clinic's
database, in the transaction `run` opens, and the letter goes out before either
is stored. Every new reaction edits `run`. `Appointments.find` raises
`AppointmentNotFound` when no appointment has that identity, and `Slots.find`
raises `SlotNotFound` when no slot has that identity. `Letters.sendCancellation`
is taken to send one letter and change nothing in the aggregates. `Letters` is
the clinic's port for a posted letter; it is not the aggregates reference's
`Notices`, which sends a patient a message.

After:

```text
interface DomainEvent

value AppointmentCancelled implements DomainEvent
  - appointment: AppointmentId
  - slot: SlotId
  - patient: PatientId
  - reason: CancellationReason
  + new(appointment: AppointmentId, slot: SlotId, patient: PatientId,
      reason: CancellationReason)
  + appointment(): AppointmentId
    return appointment
  + slot(): SlotId
    return slot
  + patient(): PatientId
    return patient
  + reason(): CancellationReason
    return reason

class Appointment
  - id: AppointmentId
  - slot: SlotId
  - patient: PatientId
  - status: AppointmentStatus
  - events: List<DomainEvent>
  - new(id: AppointmentId, slot: SlotId, patient: PatientId,
      status: AppointmentStatus)
    events := new List<DomainEvent>()
  + id(): AppointmentId
    return id
  + slot(): SlotId
    return slot
  + patient(): PatientId
    return patient
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      events.add(new AppointmentCancelled(id, slot, patient, reason))
    else
      raise AppointmentNotCancellable
    return
  + recordedEvents(): ReadOnlyList<DomainEvent>
    return events.readOnlyView()

class CancelAppointment
  - appointments: Appointments
  - outbox: Outbox
  + new(appointments: Appointments, outbox: Outbox)
  + run(id: AppointmentId, reason: CancellationReason): void
    appointment := appointments.find(id)
    appointment.cancel(reason)
    appointments.save(appointment)
    outbox.store(appointment.recordedEvents())
    return

class ReleaseSlot
  - slots: Slots
  - handled: HandledEvents
  + new(slots: Slots, handled: HandledEvents)
  + handle(id: EventId, event: AppointmentCancelled): void
    if handled.contains(id) then
      return
    else
      slot := slots.find(event.slot())
      slot.release(event.patient())
      slots.save(slot)
      handled.add(id)
    return
```

The After's `Appointment` keeps the shape the repositories skill gives
it: `- id: AppointmentId` first, the same private constructor and
`id()`, with `book` and `restore` left out of this fence. It differs
from that shape by holding the slot's identity rather than the slot
object, as rule 3 of designing aggregates asks, by the queries `slot()`
and `patient()`, and by `events`; the private constructor's body sets
`events` to an empty list. `cancel` keeps the notation's check and
error, and drops the release of the slot, which `ReleaseSlot` now makes.
`Appointments` keeps `find(id)` and `save(appointment)`; `save` stores
one whole appointment. `Slots` keeps the shape the placing domain logic
skill gives it: `find(id)` raises `SlotNotFound`, and `save(slot)`
stores one whole slot. `Slot.release(patientId)` is the notation's,
unchanged.

What is stored is the cancelled appointment under its `AppointmentId`
and its event in the outbox, both in the clinic's database, in the
transaction `run` opens; later, `ReleaseSlot` stores the released slot
under its `SlotId` and the event's identity in `HandledEvents`, both in
the clinic's database, in the handler's own transaction. `HandledEvents`
is taken to answer `contains(id)` and to store an identity through
`add(id)`; it stores the identities of the events this handler has
handled, in the clinic's database, in the same transaction as the
released slot. A relay outside this fence hands each stored event, with
the `EventId` the outbox gave it, to each handler after the commit.
`ReleaseSlot` checks `id` because the notation's `release` frees the slot
whoever holds it, so a repeated event after the slot was booked again
would free the new patient's slot: rule 5, by the identity the outbox
gave the event. The letter becomes a second handler of
`AppointmentCancelled`, shown in
[the outbox reference](references/the-outbox.md).

In the Before, `run` sends `cancel` once and `release` once. In the
After, `run` sends `cancel` once, and `ReleaseSlot.handle` sends
`release` once for the event that first finds its identity. The
constructor sets `events` before `cancel` reads it, and `handled` before
`handle` reads it; every other field arrives from a constructor
parameter named for it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A use case that sends an email, a text or a message before its
  transaction commits.
- A use case whose body grows one step for each new reaction to the same
  change.
- A domain object that holds a message bus, a mailer or a handler.
- An event named for an action to take, such as `SendReminder`, or for a
  field, such as `StatusChanged`.
- An event that carries the whole aggregate rather than the identities
  and facts its handlers use.
- A handler that changes something without checking whether it has
  handled that event before.

## Common mistakes

- Publishing the event inside the transaction, before the change
  commits.
- Letting one handler perform several unrelated reactions, so a failure
  in one repeats the others.
- Using an event for a reaction the caller must see succeed before it
  replies.
- Assuming each event arrives exactly once and in order.
- Telling the user that a reaction has happened when its handler has not
  yet run.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) draws
  the boundary that makes a reaction a later step after the commit.
- [oo-placing-domain-logic](../oo-placing-domain-logic/SKILL.md) gives
  the use-case object that opens and ends the transaction.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) keeps
  the history of transitions inside the aggregate.
- [oo-speaking-the-domain-language](../oo-speaking-the-domain-language/SKILL.md)
  finds the staff's words for the event.
- [oo-separating-reads-from-writes](../oo-separating-reads-from-writes/SKILL.md)
  keeps read models current from events and decides when event sourcing
  earns its cost.

## Further reading

- [The outbox](references/the-outbox.md)
- [Events or direct messages](references/events-or-direct-messages.md)
