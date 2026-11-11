# Consistency across aggregates

- [A later step after the commit](#a-later-step-after-the-commit)
- [When the later step fails](#when-the-later-step-fails)
- [The version check](#the-version-check)
- [One transaction over two aggregates](#one-transaction-over-two-aggregates)

Not every rule has to be true when one change commits. A rule that can
afford a short delay is brought true by a later step, and a rule that
spans aggregates is checked where many of them meet. A store must also
choose which of two copies is current when two people save at once, and
refuse the older one.

## A later step after the commit

Cancelling an appointment changes one aggregate. The freed time is then
offered to the patients on a waiting list, in a step that runs after the
cancellation commits. The step reads the freed slot and asks the waiting
list for its next patient. The caller loads the waiting list by its
identity, passes it to `run`, and saves it in its own transaction after
`run` returns.

```text
class WaitingList
  - patients: List<PatientId>
  + new()
    patients := new List<PatientId>()
  + join(patient: PatientId): void
    raises AlreadyWaiting
    if patients.contains(patient) then
      raise AlreadyWaiting
    else
      patients.add(patient)
    return
  + waiting(): ReadOnlyList<PatientId>
    return patients.readOnlyView()
  + nextPatient(): PatientId?
    return patients.first()
  + remove(patient: PatientId): void
    patients.remove(patient)
    return

class FreedTimeOffer
  - notices: Notices
  + new(notices: Notices)
  + run(waitingList: WaitingList, appointment: Appointment): void
    patient := waitingList.nextPatient()
    if patient = null then
      return
    else
      notices.send(patient, appointment.freedSlot())
      waitingList.remove(patient)
    return
```

`WaitingList` keeps the fields, constructor, `join` and `waiting` that
the composition skill gives it, and adds `nextPatient` and `remove` for
this step. `new List<PatientId>()` is taken to mean an empty list the
waiting list owns. `nextPatient()` is taken to answer the patient who has
waited longest and to change nothing; `patients.first()` answers the
patient at the front of the list, or `null` when the list is empty.
`remove` takes that patient off the list once, through
`patients.remove(patient)`. `appointment.freedSlot()` is taken to answer
the slot the cancelled appointment released. `notices.send(patient,
slot)` is taken to send one message to that patient and change nothing in
the aggregates. The constructor sets `notices` before `run` reads it, and
`run` sends one notice and removes one patient.

## When the later step fails

The cancellation and the offer run apart, so the offer can fail after the
cancellation has committed. The step is retried. Because `remove` runs
only after `notices.send` returns, a failure before the send leaves the
patient on the list and the retry offers the freed time again. A failure
after the send, before the caller stores the list, leaves the patient
waiting, so the retry sends a second notice, and the notice log holds the
evidence. A check compares the notices sent for a cancelled appointment
with the waiting list and reports a patient who is still waiting
although a notice went out, or two notices for one freed slot. The step
is not optional: a queue that drops it leaves patients waiting on time
that was already offered.

## The version check

An aggregate that is saved whole carries a version. The store stamps a
new version on save and keeps the one it last saved.

```text
class CareTeam
  - id: CareTeamId
  - version: Version
  - members: List<ClinicianId>
  + new(id: CareTeamId, version: Version)
    members := new List<ClinicianId>()
  + add(clinician: ClinicianId): void
    members.add(clinician)
    return
  + version(): Version
    return version
```

`new List<ClinicianId>()` is taken to mean an empty list the team owns.
The constructor sets `members` before `add` reads it, and sets `id` and
`version` from its parameters. `version()` returns the version the copy
was loaded with. Saving a `CareTeam` is taken to compare that version
with the stored one and raise `StaleCopy` when they differ, so the second
of two saves made from copies loaded before either wrote is refused
instead of overwriting the first change. Its caller reloads the team,
repeats the change on the current copy and saves again.

## One transaction over two aggregates

Booking reserves a slot and creates an appointment. The slot is one
aggregate and the appointment is a new one. When one store commits both,
one transaction may cover the two.

```text
class BookAppointment
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(slot: Slot, patient: PatientId): void
    appointment := Appointment.book(slot, patient)
    appointments.add(appointment)
    return
```

`Appointment.book` is the method `notation.md` gives, and it keeps the
`Slot` object inside the appointment. With the slot as its own
aggregate, rule 3 makes the appointment hold the slot's identity
instead, as the Pattern in `SKILL.md` says. The fence leaves out the
slot's own store and the transaction: the code that calls `run` saves
the reserved slot to that store and opens one transaction over it and
`Appointments`. `Appointments.add` is the store call of the port the
inverting skill declares, answered by its `DatabaseAppointments`
adapter. The constructor sets `appointments` before `run` reads it.
`run` reserves once, creates one appointment and stores it once. When
the slot and the appointment share one store, that transaction covers
both aggregates: the appointment is new, so nobody else can change it,
and a conflict on the slot refuses the whole booking. That is rule 4's
exception, stated in one place that says why. Every other rule in this
skill is brought true inside one aggregate or by a later step.
