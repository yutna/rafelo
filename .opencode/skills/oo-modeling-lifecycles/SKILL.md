---
name: oo-modeling-lifecycles
description: Use when deciding which status transitions are allowed, when something cancelled can still go ahead, or a closed one is reopened and edited.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Modeling Lifecycles

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An object that moves through states needs one place that knows how it
moves. Write the states and the transitions out of each down first,
give every transition a method of its own, and let the object refuse a
move its current state does not allow. This skill says where the state
lives, keeps final states final, gives a transition caused by time to
the object, and keeps the history the business asks about.

## When to use

- A status field exists and the changes it allows are unclear or
  disputed.
- Something cancelled is still started, completed or edited.
- A completed or closed object is reopened and changed.
- A scheduled job changes status, or should.
- The business asks when or why a status changed.

## When not to use

- The object has no status, or its status never changes after it is
  created. A value or a plain record is enough.
- Fields allow a forbidden combination at one moment, such as accepted
  and declined at once, and no move from one status to another is in
  question. That is
  [making illegal states impossible](../oo-making-illegal-states-impossible/SKILL.md).
- The same switch on a status repeats across methods, and the allowed
  transitions are not in question. That is
  [replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md).

## Core rules

1. Rule. **Write the lifecycle down as its states and, for each state,
   the transitions that leave it and what causes each, before coding
   it; then give each transition its own method named for it (`start`,
   `complete`, `cancel`).** A status that callers may set to any value
   lets them invent transitions the business never allowed. Keeping
   the status without a setter is rule 2 of
   [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md),
   with that rule's exception for a framework that maps fields at the
   edge.

2. Rule. **Make the object refuse a transition its current state does
   not allow, by raising an error named for the refused transition,
   such as `AppointmentNotCancellable`.** Every caller then gets the
   same answer without checking the status first, which is rule 3 of
   [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md).

3. Judgement. **Hold the state in the simplest form the lifecycle
   needs: an enumeration field with a check in each transition method
   while few methods depend on the state; a status object per state
   behind one interface once several methods change with it; a type per
   state when callers hold the state itself.** An enumeration with a
   check in each method is the exception that rule 4 of
   [replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
   states for one or two methods; a status object per state is that
   rule 4 once several methods change with it; and a type per state is
   rule 5 of
   [making illegal states impossible](../oo-making-illegal-states-impossible/SKILL.md).
   What tips the balance is how many methods change with the state, and
   what callers hold.

4. Rule. **Keep a final state final: a cancelled appointment or a
   completed visit takes no transition back.** Undoing one is either a
   transition the business names and allows, with its own method and
   rule, such as reopening a visit with a reason within a week, or a
   new object, such as a new appointment booked in place of the
   cancelled one.

5. Rule. **Give a transition caused by the passing of time to the
   object, as a method that is given the time, such as
   `recordNoShow(now: DateTime)`, which checks that the slot has
   ended.** A scheduled job only finds the objects that are due and
   sends each the message. The rule stays in one place, and a test can
   pass any time, because the clock arrives from outside, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   passes a clock.

6. Judgement. **Keep the history of transitions when the business asks
   what happened, not only where an object is now: record each
   transition with when it happened, who made it and why, either as
   data the new state carries (`CancellationReason`) or as a list of
   past transitions.** What tips the balance is whether anyone, such as
   a patient, an auditor or a report, asks when or why a state changed.
   When nobody does, the current state is enough.

## Pattern

Before, `Appointment` has `setStatus`, so any caller can move it to any
status: `ConsultationScreen.finish` completes an appointment that never
started, nothing stops a caller from setting `Scheduled` back on a
cancelled booking, and a booking can reach `Cancelled` without its slot
being released. After, every transition is a method of its own, the
appointment refuses a move its state does not allow, and the screen asks
for the move it means.

The `AppointmentStatus` in these fences adds `InProgress` and
`Completed` to the notation's `Scheduled` and `Cancelled`.

Before:

```text
enum AppointmentStatus
  Scheduled
  InProgress
  Completed
  Cancelled

class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + setStatus(newStatus: AppointmentStatus): void
    status := newStatus
    return
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return

class ConsultationScreen
  + finish(appointment: Appointment): void
    appointment.setStatus(Completed)
    return
```

`book` reserves the slot once and builds the appointment through the
private constructor, which sets `slot`, `patient` and `status`. `cancel`
releases the slot once. `setStatus` assigns whatever status it is
given, so `finish` completes an appointment that was never started.

After:

The lifecycle has only these moves, and a move a state refuses raises
the error named for it.

|State|Move|Goes to|A refusal raises|
|---|---|---|---|
|Scheduled|start|InProgress|`AppointmentNotStartable`|
|Scheduled|cancel|Cancelled|`AppointmentNotCancellable`|
|InProgress|complete|Completed|`AppointmentNotCompletable`|
|Completed|start, complete, cancel|nothing|each error above|
|Cancelled|start, complete, cancel|nothing|each error above|

A move asked of a state that does not list it is refused with the error
named for that move. `Completed` and `Cancelled` refuse all three.

```text
enum AppointmentStatus
  Scheduled
  InProgress
  Completed
  Cancelled

class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + start(): void
    raises AppointmentNotStartable
    if status = Scheduled then
      status := InProgress
    else
      raise AppointmentNotStartable
    return
  + complete(): void
    raises AppointmentNotCompletable
    if status = InProgress then
      status := Completed
    else
      raise AppointmentNotCompletable
    return
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return

class ConsultationScreen
  + begin(appointment: Appointment): void
    appointment.start()
    return
  + finish(appointment: Appointment): void
    appointment.complete()
    return
```

After, `Appointment` has no `setStatus`. `start` accepts only
`Scheduled`, `complete` only `InProgress`, and `cancel` only
`Scheduled`; each raises the error named for it in every other state.
In this fence, `book` is still the only way to make an appointment,
because the constructor is private. `ConsultationScreen.begin` sends
`start()`, and `finish` sends `complete()`, so the screen never reads
the status and a cancelled or completed appointment refuses both. Each
transition changes the status once, `book` reserves the slot once, and
`cancel` releases it once.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A public method that sets the status to whatever value a caller
  passes.
- Callers that check the status before every change they make.
- A final status, such as cancelled or completed, that some path
  changes back.
- A scheduled job that writes status fields itself, with its own copy
  of the rule.
- A status that nothing ever enters.
- A status that nothing ever leaves, where the business does not treat
  it as the end.

## Common mistakes

- Adding a state to the enumeration and coding the moves into it
  without writing down which transitions enter and leave it.
- Checking the allowed transitions in every caller instead of in the
  object.
- Reopening a final state by assigning the old status back, instead of
  naming the transition and its rule.
- Moving to a status object per state for a lifecycle that one or two
  methods depend on.
- Losing when and why a transition happened, until the business asks.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  tells a caller to send the action instead of reading the state.
- [oo-replacing-conditionals-with-polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  gives each status its own object when several methods change with it.
- [oo-making-illegal-states-impossible](../oo-making-illegal-states-impossible/SKILL.md)
  gives each state its own type when callers hold the state.

## Further reading

- [Transition tables](references/transition-tables.md)
- [Time and history](references/time-and-history.md)
