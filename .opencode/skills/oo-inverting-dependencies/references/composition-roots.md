# Composition roots

- [One place, one order](#one-place-one-order)
- [The locator version](#the-locator-version)
- [When a framework creates the objects](#when-a-framework-creates-the-objects)

The composition root is the one place that knows the whole object graph.
It builds each object it creates once, in the order the objects need,
and hands each one its collaborators. This reference shows a root written
by hand, the same graph reached through a service locator, and where a
framework that creates its own objects takes the root's choices.

## One place, one order

A hand-written root is a short list of constructor calls. Inside that
list, the inner call builds the adapter around the database the root
receives, then the outer call builds the object that uses it. A missing
collaborator stops the program at start-up, before a booking can fail
halfway through.

```text
class ClinicApp
  + static start(database: ClinicDatabase): AppointmentScheduler
    return new AppointmentScheduler(
      new DatabaseAppointments(database))
```

The entry script opens the database once and passes it to
`ClinicApp.start`. The method builds one `DatabaseAppointments` and one
`AppointmentScheduler`; it names the adapter, and the scheduler names
only the port. Each object is built once, and the order is the order the
objects need.

## The locator version

A service locator hides the graph behind a lookup. A domain class asks
the locator for its collaborators when a message runs, so its constructor
names only the locator, not the collaborators it uses, and the object
builds without them. The failure moves from start-up to the first
booking, and every test must fill the locator before it can run the rule.
That is the locator in domain code the skill forbids.

```text
class ServiceLocator
  + appointments(): Appointments

class BookingIntake
  - locator: ServiceLocator
  + new(locator: ServiceLocator)
  + book(slot: Slot, patient: PatientId): void
    appointments := locator.appointments()
    appointment := Appointment.book(slot, patient)
    appointments.add(appointment)
    return
```

`BookingIntake` names only `ServiceLocator` in its constructor, so a
reader cannot see that it uses `Appointments`; a test that passes a
locator without an appointment store fails only when `book` runs. The
locator also ties every test to the same lookup and hides which adapter
the program chose.

## When a framework creates the objects

A framework that creates its own objects owns their constructor calls.
Give it the root's choices through a factory or a registration, and keep
the framework's markers and base classes out of domain classes. The root
still decides which adapter the framework receives; the framework only
decides when the object is made. A request handler built this way gets
the real adapter in the program and a stand-in in a test, and the domain
class keeps no framework type.

The root's shape stays the same: one place builds the graph, and the
framework receives finished collaborators or a factory that builds them.
