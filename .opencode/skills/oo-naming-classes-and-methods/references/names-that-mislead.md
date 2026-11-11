# Names that mislead

- [A query that writes](#a-query-that-writes)
- [A boolean parameter with two jobs](#a-boolean-parameter-with-two-jobs)
- [A name that outlived its meaning](#a-name-that-outlived-its-meaning)

A name can be wrong in three common ways: it hides a write behind a
question, it folds two jobs into one method, or it keeps a meaning the
code has left behind. Each section shows the shape that misleads and the
rename that makes the code honest.

## A query that writes

`nextFreeSlot` reads like a question, but it reserves the slot before it
returns. A caller that only wants to look now takes the slot, and the
next caller finds it gone.

Before:

```text
class BookingRequest
  - schedule: Schedule
  - patient: PatientId
  + new(schedule: Schedule, patient: PatientId)
  + nextFreeSlot(clinician: ClinicianId): Slot
    raises SlotTaken
    slot := schedule.firstFreeSlot(clinician)
    slot.reserve(patient)
    return slot
```

`schedule.firstFreeSlot(clinician)` is taken to mean the first slot the
schedule holds for that clinician with no patient. `slot.reserve` is the
command the notation declares, and a taken slot raises `SlotTaken`.

After, the query only answers, and a separate command does the write:

```text
class BookingRequest
  - schedule: Schedule
  - patient: PatientId
  + new(schedule: Schedule, patient: PatientId)
  + nextFreeSlot(clinician: ClinicianId): Slot
    return schedule.firstFreeSlot(clinician)
  + book(clinician: ClinicianId): void
    raises SlotTaken
    slot := nextFreeSlot(clinician)
    slot.reserve(patient)
    return
```

The names now tell a caller which call changes the schedule. The query
can be repeated without a second effect, and `book` sends `reserve` once
per call.

## A boolean parameter with two jobs

A boolean parameter makes one method answer two questions, and every
call site has to decode the argument to know which one it asks for.
Split it into one method per job, each named for what it does.

Before:

```text
class SlotPrinter
  - slot: Slot
  - display: Display
  + new(slot: Slot, display: Display)
  + print(withPatient: Boolean): void
    if withPatient then
      display.showOccupied(slot)
    else
      display.showFree(slot)
    return
```

`display.showOccupied(slot)` and `display.showFree(slot)` are taken to
mean the display shows the slot with its patient and without one.

After:

```text
class SlotPrinter
  - slot: Slot
  - display: Display
  + new(slot: Slot, display: Display)
  + printOccupied(): void
    display.showOccupied(slot)
    return
  + printFree(): void
    display.showFree(slot)
    return
```

Each call now says on its own which output it wants. No branch is left,
and each method sends exactly one message to the display.

## A name that outlived its meaning

When a class stops being about rooms and starts booking every resource,
the old name keeps describing the old job. The change that widens it
carries the rename, and no later reader meets a `RoomBooking` that is
sometimes a device.

Before:

```text
class RoomBooking
  - room: RoomId
  - patient: PatientId
  + new(room: RoomId, patient: PatientId)
```

After:

```text
class ResourceBooking
  - resource: ResourceId
  - patient: PatientId
  + new(resource: ResourceId, patient: PatientId)
```

The fields and the constructor keep their shape; only the class name and
the name and type of the booked thing move, in the same change that gave
the class its wider job. A comment on `RoomBooking` saying "also books
devices" would leave every caller reading the old name against the new
meaning.
