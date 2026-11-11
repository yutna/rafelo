# Ports and adapters

- [A port in the domain's words](#a-port-in-the-domains-words)
- [A clock the test can fix](#a-clock-the-test-can-fix)
- [What gets a port](#what-gets-a-port)

A port is an interface the domain owns. It names what the domain needs
in the domain's words, and an adapter implements it by talking to the
outside system. This reference contrasts a domain port with a copy of an
outside client's interface, shows a clock a test can fix, and says which
outside things deserve a port.

## A port in the domain's words

`Appointments.add` says the clinic adds an appointment. The caller does
not know whether the appointment goes to a table, a queue or a file, and
a change on that side stays in the adapter. A port copied from the
database library speaks the library's language instead:
`execute(command: String)` hands over an opaque command, so every caller
still forms the library's commands and a change to the library reaches
the domain.

```text
interface Appointments
  + add(appointment: Appointment): void

interface DatabaseClient
  + execute(command: String): void
```

`DatabaseClient.execute` is taken to send one command to the outside
database once. The adapter below implements the domain port and sends
the database's own message:

```text
class ClinicDatabase
  + insert(appointment: Appointment): void

class DatabaseAppointments implements Appointments
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + add(appointment: Appointment): void
    database.insert(appointment)
    return
```

`ClinicDatabase.insert` is taken to store one appointment once. The
adapter holds the database its constructor receives, and `add` sends
`insert` once per call. No domain class names `ClinicDatabase` or
`DatabaseClient`.

## A clock the test can fix

Time is an outside dependency like a database. A class that reads the
machine clock cannot show the same result twice, and a rule that changes
at midnight is hard to observe. A `Clock` port with one message lets the
program pass a clock that reads the system time and a test pass one
fixed at a chosen moment.

```text
interface Clock
  + now(): DateTime

class SlotPlanner
  - clock: Clock
  + new(clock: Clock)
  + firstSlot(clinician: ClinicianId): Slot
    return Slot.startingAt(clinician, clock.now())
```

`Slot.startingAt` is the notation's named factory for a slot, and each
call builds a distinct slot. A test clock that returns one moment makes
every run of `firstSlot` build a new slot that starts at that moment, so
two runs give two slots, not one slot returned twice. The program's clock
reads the current time instead.

## What gets a port

A port belongs where the outside side has behaviour the domain should
not own:

- A database, a message queue, a mail server or a clock gets a port.
  Each changes, is slow, or is hard to control in a test, and a stand-in
  lets a test run without it.
- A stable library with no side effects, such as date arithmetic, is
  used directly. A port in front of it adds a seam with no variation
  behind it.
- A value, such as an identifier or a time range, is passed as it is.
  It has no outside system to hide, and wrapping it adds a class with no
  job.
- A source that has not varied and whose behaviour a test can control
  needs no port yet. Add the seam when the evidence of change, slowness
  or test difficulty arrives.
