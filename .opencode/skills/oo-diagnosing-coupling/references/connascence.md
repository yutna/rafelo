# Connascence

- [The nine kinds](#the-nine-kinds)
- [Strength](#strength)
- [Locality](#locality)
- [Degree](#degree)

Connascence is the agreement that makes two parts change together. The
vocabulary has nine kinds: five are visible in the code, and four show
themselves only while the code runs. Name the kind first, then weigh it
by strength, locality and degree.

## The nine kinds

Static kinds come first, from weaker to stronger: name, type, meaning,
position, algorithm. A reader can find them in the source. Dynamic kinds
follow, from weaker to stronger: execution order, timing, value,
identity. They need a run to show themselves, and every dynamic kind is
stronger than every static one.

### Name

Two parts must spell the same name. A booking desk calls
`Schedule.book`; when the schedule renames it to `reserve`, the desk
must change in the same commit. Weaken it by keeping the name in one
caller or one wrapper, so a rename has a single place to land.

```text
class BookingDesk
  + book(schedule: Schedule, slot: Slot, patient: PatientId): Appointment
    return schedule.book(slot, patient)
```

### Type

Two parts must agree on a type. A reminder sender takes a `PatientId`,
and a caller that passes a raw `String` no longer fits the message.
Weaken it by giving the clinic one named type and converting a raw value
once, at the edge.

```text
class ReminderSender
  + send(patient: PatientId, appointment: Appointment): void
```

### Meaning

Two parts read the same convention into a bare value. Billing and claims
both treat `2` as the family plan, while a third reader gives the same
number another meaning. Weaken it by naming the convention in one type,
an enum or a value type, and letting both sides use that type.

```text
enum PlanTier
  Basic
  Family
```

### Position

Two parts agree on the order of arguments. A call
`build(visit, "AXA", 2, true)` means nothing until the reader remembers
each slot. Weaken it by passing a parameter object, or by using named
fields, so the order stops carrying meaning.

```text
value Coverage
  - insurer: InsurerCode
  - tier: PlanTier
  - labFees: LabFees
  + new(insurer: InsurerCode, tier: PlanTier, labFees: LabFees)
```

### Algorithm

Two parts repeat the same steps and must change together. The invoice
desk and the month-end report each compute the same total, so one
discount rule changes both. Weaken it by giving the algorithm one owner
and letting the other part ask for the result.

```text
class InvoiceTotal
  - pricing: Pricing
  + new(pricing: Pricing)
  + total(visit: Visit): Money
    return pricing.total(visit)
```

### Execution order

Two parts must run their steps in a fixed order. Callers once reserved a
slot and then constructed the appointment; a missed reservation left a
held slot with no booking, and constructing a saved appointment reserved
its slot again. Weaken it by moving the order inside one named factory or
method: the booking path always reserves before it creates, and a saved
appointment is rebuilt without a reservation. The constructor is private,
so `book` and `restore` are the only ways to create an appointment.

```text
class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + static restore(slot: Slot, patient: PatientId,
      status: AppointmentStatus): Appointment
    return new Appointment(slot, patient, status)
```

### Timing

Two parts must act at the same moment. A reminder sender once had to be
called at the minute the appointment ended. Weaken it by letting the
reminder carry its own time and answer whether it is due from `sendAt`
on, so the caller no longer shares a clock.

```text
class Reminder
  - sendAt: DateTime
  + new(sendAt: DateTime)
  + due(now: DateTime): Boolean
    return now.isAtOrAfter(sendAt)
```

### Value

Several values must agree with each other. Booking and reminders each
worked out a slot's end from its start and duration, and the two ends
could drift. Weaken it by holding the related values in one value object
that sets them once.

```text
value TimeRange
  - startsAt: DateTime
  - endsAt: DateTime
  + new(startsAt: DateTime, endsAt: DateTime)
```

### Identity

Two parts must refer to the very same object. The scheduler and the
reminder log once passed an `Appointment` around, and a copy lost a
cancellation. Weaken it by passing a value that names the booking, or by
making the object immutable so a copy cannot differ.

```text
value AppointmentId
  - value: String
  + new(value: String)
```

## Strength

Strength orders the kinds from weakest to strongest: name, type,
meaning, position, algorithm, execution order, timing, value, identity.
Dynamic kinds sit above static kinds because a reader cannot see them in
the source, and within each group the later kind is stronger. A stronger
tie is not always the first to fix: strength alone ignores how many
places share it and how far it reaches. Read strength together with
locality and degree.

## Locality

Locality is distance. The same kind of tie costs less inside one class
than across a module boundary. A name shared by two methods in one class
is a rename in one file; a name spelled by the desk, the export and two
reports is four edits and four chances to miss one. Prefer the more
local form when the kind and the degree are equal.

## Degree

Degree is the count of elements that share the tie. One caller passing a
flag is a small tie; twelve callers passing the same flag make every
change twelve times larger and one site easier to miss. Degree raises
the cost of any kind. When two ties share a kind, loosen the one with
the larger degree first.
