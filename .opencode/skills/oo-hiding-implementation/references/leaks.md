# Leaks

- [A row and an error at the interface](#a-row-and-an-error-at-the-interface)
- [A release that changes nothing](#a-release-that-changes-nothing)
- [How general an interface should be](#how-general-an-interface-should-be)

A leak is a fact about the implementation that a caller must know. The
usual leaks are a storage type, a raw format and an error from an
outside system. Each one moves the module's edge outward, so a change
that should stay inside now reaches every caller.

## A row and an error at the interface

Before, `PatientDirectory` passes the table's own row and result
straight through. A caller of `find` gets a `PatientRow`, and a caller
of `register` builds a row and reads `TableResult` to learn whether the
table refused it. The storage shape crosses the module's edge, and so
does the table's own report of a problem.

```text
class PatientTable
  + find(id: PatientId): PatientRow?
  + insert(row: PatientRow): TableResult

value PatientRow
  - id: PatientId
  - name: PatientName
  + new(id: PatientId, name: PatientName)
  + id(): PatientId
    return id
  + name(): PatientName
    return name

value TableResult
  - errorCode: String?
  + new(errorCode: String?)
  + accepted(): Boolean
    return errorCode = null

class PatientDirectory
  - table: PatientTable
  + new(table: PatientTable)
  + find(id: PatientId): PatientRow?
    return table.find(id)
  + register(patient: PatientRow): TableResult
    return table.insert(patient)
```

`errorCode = null` is taken to mean that the table accepted the row;
the text in `errorCode` is the table's own code. The constructor sets
`table` before either method reads it, and the two value constructors
set their fields before any method reads them.

After, the directory speaks in the clinic's terms. `find` answers a
`PatientProfile` or raises `PatientNotFound`, and `register` raises
`PatientAlreadyRegistered` when the table refuses the row. The caller
never names `PatientRow` or `TableResult`.

```text
value PatientProfile
  - id: PatientId
  - name: PatientName
  + new(id: PatientId, name: PatientName)
  + id(): PatientId
    return id
  + name(): PatientName
    return name

class PatientDirectory
  - table: PatientTable
  + new(table: PatientTable)
  + find(id: PatientId): PatientProfile
    raises PatientNotFound
    row := table.find(id)
    if row = null then
      raise PatientNotFound
    else
      return new PatientProfile(row.id(), row.name())
  + register(patient: PatientProfile): void
    raises PatientAlreadyRegistered
    row := new PatientRow(patient.id(), patient.name())
    result := table.insert(row)
    if result.accepted() then
      return
    else
      raise PatientAlreadyRegistered
```

`table.find` answers the row or null, and `find` turns either into the
caller's profile or into `PatientNotFound`. In `find`, `row` holds the
table's answer, and this adapter is the one place that reads the storage
shape. `table.insert` answers a result that the adapter inspects, so the
table's refusal becomes `PatientAlreadyRegistered` at this edge instead
of a code every caller reads. `register` builds one row once, sends one
insert once, and either returns or raises without a second write.

## A release that changes nothing

`notation.md`'s `Slot.release` sets the patient to null whether or not a
patient was there. On a free slot it changes nothing and raises nothing,
because no caller acts on the news that the slot was already free. A
repeated `WaitingList.join` raises `AlreadyWaiting` and a repeated
`Appointment.cancel` raises `AppointmentNotCancellable`, because each
repeat may hide a caller's mistake: the patient is already waiting, or
the appointment is already cancelled. The question to ask is not
whether the state changed, but whether a caller would do anything
different on hearing that it did not.

## How general an interface should be

A method named for one screen is too narrow. `ScreenSlots.forBookingPage`
puts the page's name in the module, and the next screen that needs the
same answer must ask for another method. A method so general that every
caller writes the same glue is too wide. `freeSlots(day, clinician,
kind, includeCancelled)` hands the caller the choice of kind and of
scope, which the module should own. The middle is a message in the
caller's terms, such as `freeSlotsOn(day: Date)`, which the booking page
and a rescheduling form can both send without extra work.
