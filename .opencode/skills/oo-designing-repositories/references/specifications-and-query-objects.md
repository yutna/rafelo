# Specifications and query objects

- [Two more messages on the port](#two-more-messages-on-the-port)
- [A rule that checks one and selects many](#a-rule-that-checks-one-and-selects-many)
- [A search whose criteria combine](#a-search-whose-criteria-combine)
- [When named methods are clearer](#when-named-methods-are-clearer)

Rule 3 stops a repository from growing a general `findBy`, and rule 4
gives two shapes to the searches that remain open. A specification
names one clinic rule and can check a single aggregate and select many.
A query object carries several criteria to the store. Both keep the
clinic's question in the domain and the store's language at the edge.

## Two more messages on the port

The port below keeps the four methods the Pattern shows and adds
`select` for a specification and `search` for a query object; each
implementation translates the two into its store's query, as the
sections below describe.

```text
interface Appointments
  + add(appointment: Appointment): void
  + find(id: AppointmentId): Appointment
    raises AppointmentNotFound
  + forClinicianOn(clinician: ClinicianId, date: Date): List<Appointment>
  + save(appointment: Appointment): void
  + select(specification: AppointmentSpecification): List<Appointment>
  + search(criteria: AppointmentSearch): List<Appointment>
```

`due`, the method the lifecycles skill adds, stands as that skill writes
it. The two new methods return whole appointments, and neither one
answers a row.

## A rule that checks one and selects many

The clinician may start a consultation only once the appointment's slot
is near; earlier, the patient waits. The rule is one object, and two
callers use it: starting a consultation checks one appointment, and a
list for the reception desk selects every appointment the rule still
allows.

```text
interface AppointmentSpecification
  -- closed: the clinic's specifications are a closed set
  + isSatisfiedBy(appointment: Appointment): Boolean

value StartableNow implements AppointmentSpecification
  - cutoff: DateTime
  + new(cutoff: DateTime)
  + isSatisfiedBy(appointment: Appointment): Boolean
    return appointment.startsBy(cutoff)
  + cutoff(): DateTime
    return cutoff
```

`AppointmentSpecification` is marked closed: the clinic knows every
rule, and each implementation handles every member of the set, so a new
rule adds a case to each of them. `cutoff` is the latest slot start for
which the clinician may start a visit now, taken as the current time
plus the clinic's hour. A caller passes it in each time, so no specification
wired in at startup goes stale. `appointment.startsBy(cutoff)` is taken
to answer that the appointment is `Scheduled` and its slot starts at or
before `cutoff`, and `cutoff()` hands the same moment to a store that
translates the rule into its own query. The constructor sets `cutoff`
before either method reads it, and neither method changes anything.

One appointment is checked when a consultation starts:

```text
class StartConsultation
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(id: AppointmentId, cutoff: DateTime): void
    raises ConsultationNotStartable
    appointment := appointments.find(id)
    specification := new StartableNow(cutoff)
    if specification.isSatisfiedBy(appointment) then
      appointment.start()
      appointments.save(appointment)
    else
      raise ConsultationNotStartable
    return
```

`StartConsultation` holds the port, set by its constructor, and builds
the rule once per call from the cutoff `run` is given. `run` finds the
whole appointment, asks the specification, and either sends `start()`
once and saves the appointment or raises `ConsultationNotStartable`;
the two branches never both run. `start()` is the lifecycles skill's
transition, and it refuses an appointment that is not `Scheduled`.
Reception checks a patient in as a separate move, and this use case
starts the consultation for the clinician. `AppointmentNotFound` from
`find` and `AppointmentNotStartable` from `start` pass to the caller.
`ConsultationNotStartable` means the rule refused this start.
`StartConsultation.run` opens the transaction and ends it after `save`,
and the fence leaves those boundaries out. What is stored is the whole
appointment, in the `Appointments` store, in that transaction, and no
other aggregate changes.

Many are selected when the reception desk asks which appointments the
clinician may start now:

```text
class StartableAppointments
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(cutoff: DateTime): List<Appointment>
    specification := new StartableNow(cutoff)
    return appointments.select(specification)
```

`run` builds the rule once per call and asks the store for every
appointment it accepts. Because the specifications are a closed set,
each implementation handles every member, so a database implementation
turns `StartableNow` into one query: the status is `Scheduled`
and the slot starts at or before `specification.cutoff()`. An in-memory
implementation sends `isSatisfiedBy` to each stored appointment and
answers the same list. The fence changes nothing, so `run` opens no
transaction.

## A search whose criteria combine

The reception desk searches by any mix: a clinician, a date range, a
kind of appointment, or none of them. No single name can say which
combination a caller has in mind, so the criteria travel as one object.

```text
value AppointmentSearch
  - clinician: ClinicianId?
  - from: Date?
  - to: Date?
  - kind: AppointmentKind?
  + new(clinician: ClinicianId?, from: Date?, to: Date?,
      kind: AppointmentKind?)

class FindAppointments
  - appointments: Appointments
  + new(appointments: Appointments)
  + run(criteria: AppointmentSearch): List<Appointment>
    return appointments.search(criteria)
```

The constructor sets the four criteria; an absent criterion is null, so
a caller can leave any of them out. `AppointmentKind` is taken to name
the clinic's kinds of appointment, such as a consultation or a
procedure. `FindAppointments` holds the port, set by its constructor,
and `run` sends one message. A database implementation turns the
criteria into one query: it adds a condition for each value that is
present, leaves out each one that is null, and passes the values in the
order of the conditions. No caller writes query text or receives a
query builder. An in-memory implementation checks each stored
appointment against the same criteria. The fence changes nothing and
opens no transaction.

## When named methods are clearer

Two or three fixed questions do not earn either shape. `forClinicianOn`
answers one clinician's day, `forSlot` answers the appointments booked
into one slot, and `upcomingFor` answers the next few for one clinician.
Each name says what the clinic asks and which aggregates come back, and
a reader needs no criteria type to use it.

A specification pays when one rule is needed both to check one object
and to select many, so the rule is written once and no caller copies
it. A query object pays when criteria combine freely and the number of
combinations is far larger than the number of useful names. When the
questions are stable and few, keep the named methods, because a name
is the clearest interface a caller can read.
