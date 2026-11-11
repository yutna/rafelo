# Time and history

- [A transition the clock causes](#a-transition-the-clock-causes)
- [A history the business can read](#a-history-the-business-can-read)
- [Undoing a final state](#undoing-a-final-state)

Two kinds of change are easy to leave out of a lifecycle: the ones the
clock causes, and the record of what already happened. This reference
keeps both. A rule about time stays in the object that owns the state,
and the record of changes lives in that object's aggregate when the
business asks for the history.

## A transition the clock causes

A no-show is decided by time, not by a person. `Appointment` answers
`recordNoShow(now)`; it accepts the move only from `Scheduled`, and
only after the slot has ended. The nightly job asks the store for the
appointments whose slot has ended and sends each one the message. The
store is the inverting dependencies skill's `Appointments` port, with
its `DatabaseAppointments` adapter; this fence adds `due` to the port
and leaves `add` as it is.

```text
interface Appointments
  + add(appointment: Appointment): void
  + due(now: DateTime): List<Appointment>

enum AppointmentStatus
  Scheduled
  InProgress
  Completed
  Cancelled
  NoShow

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
  + recordNoShow(now: DateTime): void
    raises AppointmentNoShowNotRecordable
    if status = Scheduled then
      if slot.hasEndedBy(now) then
        status := NoShow
      else
        raise AppointmentNoShowNotRecordable
    else
      raise AppointmentNoShowNotRecordable
    return

class NoShowRun
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(now: DateTime): void
    appointments.due(now).recordNoShow(now)
    return
```

`AppointmentStatus` here adds `NoShow` to the four members the Pattern
uses, so a missed visit has a state of its own. `slot.hasEndedBy(now)`
is taken to mean that the slot's end, its start plus the length the
clinic gives it, is at or before `now`. `appointments.due(now)` returns
the appointments whose slot has ended by `now` and whose status is
still `Scheduled`; `appointments.due(now).recordNoShow(now)` is taken
to send `recordNoShow(now)` to each of them once. `recordNoShow` checks
the status and the slot again, so a direct call on any other state, or
on one whose slot has not ended, raises `AppointmentNoShowNotRecordable`
and changes nothing. The job holds the port, not the database, and
passes the time it was given, so a test can pass any moment. This fence
leaves out the store, and each appointment's change is stored in its
own transaction, as rule 4 of `oo-designing-aggregates` asks.

## A history the business can read

When the only question is where an appointment is now, the enumeration
is enough. When a report asks every change, the object needs a record
of them. Each entry says which state was reached and when; it names the
clinician who made the change when a clinician did, and a cancellation
also says why. The list is read-only from outside, so a report cannot
edit the history it reads.

```text
value AppointmentChange
  - status: AppointmentStatus
  - at: DateTime
  - by: ClinicianId?
  - reason: CancellationReason?
  + new(status: AppointmentStatus, at: DateTime,
      by: ClinicianId?, reason: CancellationReason?)

class AppointmentHistory
  - changes: List<AppointmentChange>
  + new()
    changes := new List<AppointmentChange>()
  + record(change: AppointmentChange): void
    changes.add(change)
    return
  + changes(): ReadOnlyList<AppointmentChange>
    return changes.readOnlyView()
```

`new List<AppointmentChange>()` is taken to mean an empty list the
history owns. `record` appends one entry once, and `changes` returns a
read-only view, so every reader sees the same list and no reader
changes it. The entry for a cancellation carries the
`CancellationReason` and the moment, so the answer to why survives
after the status has moved on. The entry also names the clinician who
made the change when a clinician did; a change the clock made leaves it
null, and the time still says when. `Appointment` keeps the notation's
three fields, so this fence shows the history alone: the history
belongs to the appointment's aggregate, and a caller reaches it through
the root. A use case that cancels an appointment, or a job that keeps
history, writes the entry in the same transaction as the change. A
change without its entry is history the business asked for and did not
get. When nobody asks when or why, the current state is enough, and the
list is cost without a reader.

## Undoing a final state

A cancelled appointment is not moved back to `Scheduled`. When the
patient still needs care, `Appointment.book` reserves a new slot and
creates a new appointment; the cancelled one keeps its status and its
history. A completed visit is final in the same way. When the business
allows a correction, it names the transition, such as `reopen(reason)`
with a rule for how late it may happen, and gives it its own error. The
status is never assigned back by a caller, because that is the move the
lifecycle forbids.
