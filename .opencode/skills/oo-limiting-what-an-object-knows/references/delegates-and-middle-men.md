# Delegates and middle men

- [Hiding a delegate](#hiding-a-delegate)
- [Removing a middle man](#removing-a-middle-man)
- [Moving a method to its data](#moving-a-method-to-its-data)

Hiding a delegate and removing a middle man are the two directions of one
balance. The first gives a caller a shorter path to what it wants. The
second deletes a class that made a path short but added nothing. This
reference shows each move, then the change of address that ends a chain
for good.

## Hiding a delegate

A check-in desk prints the room a patient should walk to. Before, it
walks three objects to find the name.

```text
class CheckInDesk
  + direct(appointment: Appointment): RoomName
    return appointment.slot().room().name()
```

The desk knows that an appointment holds a slot, that a slot holds a
room, and that a room answers a name. None of those objects belongs to
the desk, and a change to any of them breaks it.

After, the desk asks the appointment, and each object passes the request
to its own neighbour.

```text
class CheckInDesk
  + direct(appointment: Appointment): RoomName
    return appointment.roomName()

class Appointment
  - slot: Slot
  - patient: PatientId
  - kind: AppointmentKind
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, kind: AppointmentKind,
      status: AppointmentStatus)
  + roomName(): RoomName
    return slot.roomName()

class Slot
  - clinician: Clinician
  - startsAt: DateTime
  - length: Duration
  - patient: PatientId?
  - room: Room
  - new(clinician: Clinician, startsAt: DateTime,
      length: Duration, patient: PatientId?, room: Room)
  + roomName(): RoomName
    return room.name()
```

`RoomName` is taken to be the value a room answers for its name. `Slot`
in this section also holds the `Room` it is in, and the fence declares
that field. Each object talks only to its own field, and each forward
hides one step rather than replacing the object underneath. The cost is
visible: every new question about a room adds a method to two classes.
Hiding a delegate contains change, and the forwards are what it costs.

## Removing a middle man

A booking class forwards every calendar message and adds no rule of its
own.

```text
class Booking
  - calendar: Calendar
  + new(calendar: Calendar)
  + add(appointment: Appointment): void
    calendar.add(appointment)
    return
  + remove(appointment: Appointment): void
    calendar.remove(appointment)
    return
  + entries(date: Date): List<Appointment>
    return calendar.entries(date)
  + find(patient: PatientId): Appointment?
    return calendar.find(patient)
```

`Booking` adds no rule: every message it answers is the calendar's
message under the same name. A new calendar feature means a new `Booking`
method, so the class grows with its collaborator and hides nothing that
changes. After, the screen that used to call `Booking` holds the calendar
itself.

```text
class SchedulingScreen
  - calendar: Calendar
  + new(calendar: Calendar)
  + reschedule(from: Appointment, to: Appointment): void
    calendar.remove(from)
    calendar.add(to)
    return
```

The screen's `reschedule` is its own rule, made of two calendar messages.
The screen that used to call `Booking` now holds the calendar and sends it
the messages itself; no forwarding class takes `Booking`'s place.
`Calendar` is a collaborator with behaviour, so holding it directly ties
the screen no more tightly than holding `Booking` did.

A class stays when it hides a boundary on purpose: an adapter in front of
an outside calendar service, or the single entry point a module
publishes. Those forwards are the point, because they keep the outside
shape away from the rest of the code.

## Moving a method to its data

A booking desk describes a slot, and every message the method sends goes
to the slot it was given.

```text
class BookingDesk
  - calendar: Calendar
  + new(calendar: Calendar)
  + describe(slot: Slot): SlotSummary
    return new SlotSummary(slot.clinician(), slot.startsAt(),
      slot.length())
```

`describe` reads none of the desk's own fields, so it uses none of its
own data. It belongs on `Slot`, where the start time, the length and the
clinician live.

```text
class Slot
  - clinician: Clinician
  - startsAt: DateTime
  - length: Duration
  - patient: PatientId?
  - new(clinician: Clinician, startsAt: DateTime,
      length: Duration, patient: PatientId?)
  + describe(): SlotSummary
    return new SlotSummary(clinician, startsAt, length)
```

`SlotSummary` is taken to be a value built from a clinician, a start time
and a length. Each read is now of a field `Slot` owns, and the three
getters that existed only to feed the desk can go. A method that stays
behind as a forward keeps the old path alive, and the forward and the
moved method drift apart. Move the callers, then delete the shell.
