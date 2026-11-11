# Services by layer

- [The table](#the-table)
- [The application service](#the-application-service)
- [The domain service](#the-domain-service)
- [The entity method](#the-entity-method)
- [Telling them apart](#telling-them-apart)

Three kinds of object share the work of a rule in a module that uses a
domain model. The application service runs one use case. The domain
service decides an operation that no single aggregate can decide. The
entity method decides something about the object that holds the data.
The table below says what each holds, what it may know and what it
returns, and each section then shows one booking example.

## The table

|Kind|Holds|May know|Returns|Example|
|---|---|---|---|---|
|Application|Ports|Repositories, transaction|Reply or none|BookAppointment|
|Domain|No state|Given values, a port|Decision or value|VisitPricing|
|Entity|Fields|Own fields, parameters|A decision, a value, or none|Slot.reserve|

The application service holds the ports one use case needs and may know
repositories and the transaction. The domain service holds no field
between calls and may know the values and aggregates it is given, plus
any port it receives through its constructor. The entity method holds
its own fields and may know only them and its parameters.

## The application service

`BookAppointment` is the object one booking request runs in. It loads the
slot, lets the domain build the appointment, stores both changes and
answers nothing.

```text
interface Slots
  + find(id: SlotId): Slot
    raises SlotNotFound
  + save(slot: Slot): void

class BookAppointment
  - slots: Slots
  - appointments: Appointments
  + new(slots: Slots, appointments: Appointments)
  + run(slotId: SlotId, patient: PatientId): void
    slot := slots.find(slotId)
    appointment := Appointment.book(slot, patient)
    slots.save(slot)
    appointments.add(appointment)
    return
```

`Slots` is a port in the repository's shape: `find` is taken to answer one
whole slot, and `save` to store one whole slot. The store finds and saves
a slot by a `SlotId` it carries, which `notation.md`'s sketch leaves out.
`Appointments` is the port the inverting skill declares and the
repositories skill extends; this fence sends it `add` alone, which stores
one appointment once. `Appointment.book` is the notation's factory: it
reserves the slot once and builds the appointment that holds it. The
aggregates skill decides whether that appointment holds the slot or the
slot's identity; this reference shows the use-case coordination, not that
boundary. `BookAppointment` is the booking in the aggregates skill's
reference, with the slot's store included, and takes the slot's identity
rather than the slot.

`BookAppointment.run` opens the transaction before `slots.find` and ends
it after `appointments.add`; the fence leaves those boundaries out. What
is stored is the reserved slot in `Slots` and the new appointment in
`Appointments`, in that one transaction. Booking creates one aggregate
while it changes another, which is the exception the aggregates skill
allows for one store and one transaction.

The body has no business condition. A rule that refuses a taken slot
lives in `Slot.reserve`, and a rule about the price would live in a
domain service. `BookAppointment` only coordinates.

## The domain service

`VisitPricing` decides a fee that no single aggregate can decide: it
needs the rates and the patient's coverage together, and the fee belongs
to neither object alone.

```text
class VisitPricing
  + quote(kind: AppointmentKind, length: Duration,
      rates: Rates, coverage: Coverage): Fee
    fee := rates.feeFor(kind, length)
    if coverage.includes(kind) then
      return coverage.patientShareOf(fee)
    else
      return fee
```

`VisitPricing` holds no field and has no constructor. `quote` takes the
kind, the length, the rates and the coverage and returns a `Fee`; it
sends `rates.feeFor` once, and sends `coverage.includes` once and
`coverage.patientShareOf` once along one branch.
`rates.feeFor(kind, length)` is the `Rates` value's own message from
the limiting skill. `Coverage.includes(kind)` is taken to mean that the
coverage covers that kind of appointment, and
`Coverage.patientShareOf(fee)` the part of that fee the patient pays.

The fence changes and stores nothing, so it opens no transaction. A
domain service that needed an answer from outside would receive that port
through its constructor; this one needs none, so it holds nothing between
calls.

## The entity method

`Slot.reserve` decides whether the slot can take the patient. The slot
holds the field the decision reads.

```text
class Slot
  - clinician: ClinicianId
  - startsAt: DateTime
  - patient: PatientId?
  + reserve(patientId: PatientId): void
    raises SlotTaken
    if patient = null then
      patient := patientId
    else
      raise SlotTaken
  + release(patientId: PatientId): void
    patient := null
```

The fence keeps `notation.md`'s three fields and leaves the constructor
out; `oo-assigning-responsibilities` shows only `patient` for its
cancellation rule, and `oo-limiting-what-an-object-knows` gives the slot
a `Clinician` and a `length` for its fee example. `reserve` reads
`patient` once, sets it once when it is absent and raises `SlotTaken`
once when it is present. `release` sets `patient` back to null.

The method knows its own fields and its parameter, and nothing else: no
repository, no port and no transaction. It changes the slot in memory,
and the fence stores nothing; the application service saves the whole
slot through `Slots.save` in the transaction it opened.

## Telling them apart

- A domain service that loads or stores aggregates has become an
  application service. It now knows a repository and the transaction, and
  the use case only forwards to it.
- A domain service that reads one aggregate's data and decides for it is
  an entity method in disguise. A `VisitPricing` that took an
  `Appointment` and read its kind and length would be one; the version
  here takes the values it needs instead, so the appointment keeps its
  own data.
- An application service that holds a business condition is doing the
  domain's work. Move the condition to the aggregate that holds the data,
  or to a domain service when several aggregates are needed.
- An entity method that needs a repository, a port or the transaction has
  outgrown the entity. Move the coordination to an application service
  and keep the decision on the entity.
