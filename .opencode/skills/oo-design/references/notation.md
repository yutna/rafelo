# Neutral notation

- [Declarations](#declarations)
- [Enumerations](#enumerations)
- [Members](#members)
- [Fields](#fields)
- [Methods](#methods)
- [Constructors](#constructors)
- [Extension](#extension)
- [Errors](#errors)
- [Bodies](#bodies)
- [Comments and types](#comments-and-types)
- [Functions](#functions)
- [Complete example](#complete-example)

## Declarations

A `class` names an object with identity: two instances are equal only
when they are the same object. An `interface` names a set of messages
another object answers. A `value` is immutable and compares by value.

```text
class Appointment
interface AppointmentPolicy
value PatientId
```

## Enumerations

An `enum` lists its members on the following lines.

```text
enum AppointmentStatus
  Scheduled
  Cancelled
```

## Members

Members are indented two spaces. `-` marks a private member and `+`
marks a public one.

```text
class Appointment
  - status: AppointmentStatus
  + cancel(reason: CancellationReason): void
```

## Fields

A field is written as `- name: Type` inside its class.

```text
class Appointment
  - status: AppointmentStatus
```

## Methods

A method is written as `+ name(parameter: Type): ReturnType` inside its
class. A `static` method belongs to the class, not to an instance, and
is called on the class name:
`Slot.startingAt(clinician, startsAt)`. A named factory is a `static`
method that returns `new ...`.

```text
class Slot
  + static startingAt(clinician: ClinicianId, startsAt: DateTime): Slot
    return new Slot(clinician, startsAt)
  + reserve(patient: PatientId): void
```

## Constructors

A constructor is written as `+ new(parameter: Type)` and has no return
type. A constructor parameter with the same name as a field sets that
field. A constructor written as `- new(...)` is private: only the
class's own methods, `static` or not, may call it.

```text
class Appointment
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
```

## Extension

`extends` and `implements` sit on the declaration line. A message sent
with no receiver goes to the object itself. A subclass method with the
same signature as a parent method overrides it; inside it,
`super.name(args)` sends the message to the parent's version.

```text
class Appointment extends Booking implements Cancellable
  + confirm(): void
    super.confirm()
    remindPatient()
  - remindPatient(): void
```

## Errors

A method that can fail puts `raises Name` on the line under its
signature. `raises` names each error the method raises itself with
`raise`; two or more are written `raises A, B`. An error raised by a
message the method sends passes on to its caller. The method may name
it in `raises` too, when its callers must handle it.

```text
class Slot
  + reserve(patient: PatientId): void
    raises SlotTaken
```

## Bodies

A body is indented under its signature and holds plain statements:
`if … then … else …`, `raise X`, `return x`, a message send, and
construction with `new`. `:=` assigns, `=` compares, `null` is the
absent value of a `Type?`, and `void` means the method returns
nothing. A bare `return` ends a `void` method.
An `if … then …` may leave out its `else`, and then does nothing when
the condition is false.

```text
class Appointment
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
```

## Comments and types

`--` starts a comment. A `Type?` may be absent. `List<Type>` is a
collection. `add(x)` appends `x` to the list in place, `contains(x)`
is true when the list holds an item equal to `x`, `copy()` returns a
new list with the same items, and `readOnlyView()` returns a
`ReadOnlyList<Type>` that shows the list but cannot change it.

```text
value CancellationReason
  -- why the appointment was cancelled
  + new(note: String?)
class Clinician
  + appointments(date: Date): List<Appointment>
```

## Functions

`(Type) -> Type` is the type of a function value: it takes values of
the types in the parentheses and answers a value of the type after the
arrow. `(name: Type) -> expression` writes a function value. A function
value answers one message, `call(args)`, which runs it and answers its
result.

```text
class ReminderCheck
  - isDue: (Appointment) -> Boolean
  + new(isDue: (Appointment) -> Boolean)
  + shouldRemind(appointment: Appointment): Boolean
    return isDue.call(appointment)
```

## Complete example

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
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return

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

The notation has no other keywords than those above, `static` included,
and no semicolons.
