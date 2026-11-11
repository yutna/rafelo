# Persistence ignorance

- [What the domain does not know](#what-the-domain-does-not-know)
- [The store behind the port](#the-store-behind-the-port)
- [An in-memory store for tests](#an-in-memory-store-for-tests)

A repository's interface promises whole aggregates in the domain's
types. Its implementation keeps that promise by translating at the
edge: a call loads a record, rebuilds one aggregate, and a change is
written back whole. This reference lists what a domain class never
sees, shows the appointment adapter, and shows an in-memory store that
lets the domain be tested without a database.

## What the domain does not know

A domain class knows the messages its repository answers and nothing
about how they are answered. It does not hold a connection, a session
or a transaction. It does not see a row, a table name, a column or a
piece of query text. It carries no storage marking, such as an
annotation or an attribute that names a table, and no base class from a
storage library. And no object is loaded behind its back: an object it
holds was built through its own factory, not filled in from outside
after its constructor ran.

Each of those things ties the class to one store, and a rule tested
through the class then needs that store running. Keeping them at the
edge means the domain can be built in a test with a store that holds
its aggregates in memory, and the rule can be exercised with no
database, no schema and no network.

## The store behind the port

The store speaks in its own records. The port speaks in appointments,
so the adapter reads and writes records and builds appointments through
`Appointment.restore`.

```text
class ClinicDatabase
  + insert(appointment: Appointment): void
  + appointmentById(id: AppointmentId): AppointmentRecord
    raises NoSuchRecord
  + appointmentsByClinicianOn(clinician: ClinicianId,
      date: Date): List<AppointmentRecord>
  + update(appointment: Appointment): void
```

`insert` is the inverting dependencies skill's message and is taken to
store one appointment once. `appointmentById` is taken to read the
record stored under an id and to raise `NoSuchRecord` when no record is
stored there. `appointmentsByClinicianOn` is taken to read the records
for one clinician on one day. `update` is taken to replace the record
stored under the appointment's id. `AppointmentRecord` is taken to be
the store's own row for an appointment: its id, slot, patient and
status as columns. This fence keeps the shape the inverting skill gives
`ClinicDatabase` and adds the three messages the adapter sends; the
store's fields and constructor stay outside this skill. The store writes
only inside the transaction the adapter's caller opened, so this fence
leaves the transaction's boundaries out.

The adapter holds the database and answers every message of the port:

```text
class DatabaseAppointments implements Appointments
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + add(appointment: Appointment): void
    database.insert(appointment)
    return
  + due(now: DateTime): List<Appointment>
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
  + forClinicianOn(clinician: ClinicianId, date: Date): List<Appointment>
  + save(appointment: Appointment): void
  + select(specification: AppointmentSpecification): List<Appointment>
  + search(criteria: AppointmentSearch): List<Appointment>
```

`database`, set by the constructor, is the field the inverting skill
gives this adapter. `find`, `save` and `due` have no body in the fence:
`find` reads one record through `database.appointmentById` and rebuilds
it with `Appointment.restore`, `save` sends `database.update` the whole
appointment once, and `due` answers the appointments whose slot has
ended by `now` and whose status is still `Scheduled`, the lifecycles
skill's question. `forClinicianOn` reads the day's records and rebuilds
each one the same way. `add` sends `insert` once. `select` and `search`
are the two query messages of the specifications reference; this
adapter turns each into one query over its records. The store raises
`NoSuchRecord` for an absent id, and the adapter answers
`AppointmentNotFound` instead, so no store type or store error crosses
the port. What `save` stores is the whole appointment, in the clinic
database, in the transaction the code that calls it opened; the adapter
never commits or rolls back.

Rebuilding goes through a factory of the appointment's own class:

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
```

`Appointment` keeps the notation's `slot`, `patient` and `status` and
adds `- id: AppointmentId` first, which its private constructor, `book`
and `restore` take and `id()` answers, so the store finds and saves an
appointment by the identity it carries; `notation.md`'s sketch leaves
that field out. `restore` rebuilds a stored appointment without running
`book`, and `book` still reserves the slot once. The fence leaves the
slot's own store and the transaction out; it shows the appointment's
factory alone. `AppointmentStatus` is the lifecycles skill's four-member
enumeration, so `Scheduled` is the value it gives that member. The
constructor sets every field before any method reads one, and `id()`
changes nothing.

## An in-memory store for tests

A test does not need a database to exercise a use case. The same port
with a store that keeps its appointments in a collection is enough, and
it answers the same error. `find` answers with the stored object itself,
not a copy, so a use case that changes an appointment and forgets `save`
still passes against this store.

```text
class InMemoryAppointments implements Appointments
  - appointments: Map<AppointmentId, Appointment>
  + new()
    appointments := new Map<AppointmentId, Appointment>()
  + add(appointment: Appointment): void
    appointments.put(appointment.id(), appointment)
    return
  + due(now: DateTime): List<Appointment>
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
    appointment := appointments.get(id)
    if appointment = null then
      raise AppointmentNotFound
    else
      return appointment
  + forClinicianOn(clinician: ClinicianId, date: Date): List<Appointment>
  + save(appointment: Appointment): void
    appointments.put(appointment.id(), appointment)
    return
  + select(specification: AppointmentSpecification): List<Appointment>
  + search(criteria: AppointmentSearch): List<Appointment>
```

`Map<AppointmentId, Appointment>` is taken to be a collection keyed by
the appointment's identity; `new Map<AppointmentId, Appointment>()`
starts it empty, `put(key, value)` stores under the key, and `get(key)`
answers what is stored there or null. The constructor sets
`appointments` before any method reads it. `add` stores one appointment
once, `find` raises `AppointmentNotFound` for an absent id and changes
nothing, and `save` replaces the stored appointment once. The fence
leaves the bodies of `due`, `forClinicianOn`, `select` and `search`
out; each answers the same list as its database counterpart, because it
checks each stored appointment against the same moment, day, rule or
criteria. The in-memory store keeps the whole appointment in its map and
opens no transaction, because a test calls one use case and nothing else
changes at the same time.

A test builds the domain with this store and runs the use case. It
checks the appointment's decision, not the database's query, and it
needs no running server. The same port has two implementations, so the
domain can be exercised without the database and a change at the edge
stays outside the domain's code.
