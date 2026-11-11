# Two meanings of one word

A word the staff share can hide two concepts. Reception and billing may
both say *appointment*, but one means a slot that is booked and the
other means a visit that can be charged. One class that serves both
collects fields and flags that only one group reads, and each group
learns to ignore the half it does not use.

- [One class for two meanings](#one-class-for-two-meanings)
- [Two classes with their own words](#two-classes-with-their-own-words)
- [A glossary entry](#a-glossary-entry)
- [Signs of two owners](#signs-of-two-owners)

## One class for two meanings

The class below is the appointment both groups edit. Reception reads
`patient`, `slot` and `status`; billing reads `billable` and
`invoiceNumber`. The billing flag is set by billing alone, and
reception's screen never shows it.

```text
class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - billable: Boolean
  - invoiceNumber: String?
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
    billable := false
    invoiceNumber := null
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + markBilled(number: String): void
    billable := true
    invoiceNumber := number
    return
  + isBilled(): Boolean
    return billable
  + invoice(): String?
    return invoiceNumber
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return
```

`false` and `true` are taken to mean the two values a `Boolean` can
hold. The `Appointment` here follows the notation's class and adds the
two billing fields, `billable` and `invoiceNumber`, that reception never
reads. The constructor sets those fields once, `markBilled` sets both
once, `isBilled` and `invoice` read them without changing anything, and
`cancel` sets the status and releases the slot once. Nothing stops
billing from marking an appointment billed after reception cancelled
it, because the class holds both decisions and neither group sees the
other's rule.

## Two classes with their own words

The split keeps the booked slot as reception's `Appointment` and gives
billing its own `BillableVisit`, which names the appointment it prices.
Each class has one meaning, and no field waits for a group that will
never read it.

```text
class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return

class BillableVisit
  - appointment: AppointmentId
  - invoiceNumber: String?
  + new(appointment: AppointmentId)
    invoiceNumber := null
  + bill(number: String): void
    raises VisitAlreadyBilled
    if invoiceNumber = null then
      invoiceNumber := number
    else
      raise VisitAlreadyBilled
    return
  + invoice(): String?
    return invoiceNumber
```

`Appointment` in this fence is the notation's class again: the
constructor sets `status` once, `book` reserves the slot and creates the
appointment, and `cancel` changes the status and releases the slot
once. `BillableVisit` sets `invoiceNumber` once in its constructor and
once in `bill`, and `invoice` reads it without changing anything. The
identifier keeps the two models apart while billing can still name the
appointment it prices, and a second `bill` is refused instead of
overwriting the first invoice number.

## A glossary entry

When the groups agree on a word, write down what it means and the words
it replaces. A short entry beside the code is enough:

- Word: *billable visit*.
- Meaning: a visit the clinic keeps and can charge, with one patient
  and one clinician.
- Replaces: *appointment* in billing code, and *encounter* in the old
  reports.

The entry is part of the code's documentation. When a name changes, the
entry changes in the same commit; a glossary that describes a word the
code no longer uses sends the next reader the wrong way.

## Signs of two owners

Two meanings usually belong to two separately owned parts of the code.
These are signs to look for, not a new class to extract:

- Each meaning has its own group of readers, and the groups change the
  class for unrelated reasons.
- The fields split into two groups that never meet in one use case.
- One group protects its half with a flag, a status or a comment, while
  the other group ignores it.
- The two groups release, test or deploy their code separately.
- Each group already has its own word in its own documents, and only
  the shared class uses one word for both.

When those signs hold, give each meaning its own model and let the two
models meet through an identifier or a narrow query. Where the line
between the two models runs is a question of context boundaries.
