---
name: oo-assigning-responsibilities
description: Use when deciding which class owns a behaviour, where a method lives, which object holds its data or creates another, or when a class does too much.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Assigning Responsibilities

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Every behaviour needs an owner. This skill chooses the class that should
answer a request, create another object, or take on a new rule. It starts
from the information an object holds, falls back to a service only when
no domain object stays cohesive, and breaks ties with coupling and
cohesion. The result is a small set of classes that each have one reason
to change.

## When to use

- A behaviour has no obvious class, or two classes could own it.
- A new method is about to land in a service, controller or helper.
- One class has grown methods for unrelated parts of the clinic.
- A request goes from the interface straight to a domain object, or the
  interface holds a business condition.
- An object needs to be created and the owner of construction is
  unclear.
- A design review needs class names, responsibilities and collaborators
  before code.

## When not to use

- The change fixes one method whose owner is not in question. Keep the
  owner and change the body.
- The module is written as data and functions, not objects. Follow its
  idiom and do not force objects onto it.
- The question is only where to put a line of formatting or logging,
  and no domain rule is involved.

## Core rules

1. Default. **Give a behaviour to the object that holds the information
   it needs.** If a class already holds the values a decision reads,
   the decision belongs there. Asking another object for those values
   and deciding outside puts the rule and its data in different places,
   where they drift apart.

   The exception is a behaviour that would drag a database, a
   framework or another context into the object. Give it to a
   collaborator, as rule 4 describes.

2. Default. **Create an object where its lifetime is controlled: in the
   object that contains, records, or closely uses it, or in the object
   that holds its initial data.** A new object belongs where its
   lifetime is managed and its data is at hand. A clinic creates its
   schedule, the schedule creates its slots, and a booking use case
   creates an appointment for a slot.

   The exception is an object that must outlive its creator or cross a
   module boundary. A factory owns construction in that case, while the
   creator keeps the relationship.

3. Rule. **Insert an intermediary when two objects must not know each
   other.** The intermediary exposes only the messages the caller needs
   and translates them into the other object's language. It owns no
   domain rule of its own; it only routes and adapts.

4. Default. **Keep a behaviour in a domain object.** A domain object
   that holds the data usually has the best claim. A service is a last
   resort, not the first place a new rule goes.

   The exception is a rule that no domain object can hold without
   losing cohesion. Put it in a service named after the clinic activity
   it performs, such as booking or cancellation, not after a technical
   layer or a pattern.

5. Rule. **Send a request from a user interface or API first to a
   use-case object that delegates.** The use-case object names the
   operation, loads what it needs, and asks domain objects to decide.
   The interface does not call a domain object directly, and a business
   condition does not stay in the interface layer.

6. Judgement. **Keep each class to one or two roles, named in plain
   words.** A class that holds information may also structure other
   objects, but it should not also coordinate a flow and talk to the
   outside world. Name the role in a review: it holds information, it
   structures other objects, it provides a service, it coordinates
   others, it controls a flow, or it talks to the outside world. If a
   class needs three roles, split it or move one role to a collaborator.
   These are checks, not a fixed taxonomy; use the words that fit the
   class.

7. Default. **Give each class one reason to change: one kind of change
   request.** If two kinds keep landing on the same class, split the
   class along the line between them. A method that changes for the same
   reason as its neighbours stays.

   The exception is two kinds of change that always arrive in the
   same request. Splitting them would make every such request touch
   two classes, so keep them together until they arrive apart.

8. Rule. **Extract a class when one class knows and does too much.**
   Symptoms are a growing list of unrelated methods, groups of methods
   that each use their own group of fields, and a name that needs "and"
   to describe it. Move the
   fields and methods that change together into a new class, give it a
   domain name, and keep the original as a collaborator. The reference
   on extracting a class starts from a `ClinicManager` that books,
   reminds and invoices.

9. Default. **Test a design before code with a responsibility card.**
   Write the class name, its responsibilities and its collaborators on
   one card. If a responsibility needs a second card to explain, or a
   collaborator is there only to fetch data, revise the design. The card
   walkthrough for booking an appointment is in the Object roles
   reference.

   The exception is a change already excluded by the When not to use
   section. Do not card a fix inside one method.

10. Judgement. **Break a tie with coupling and cohesion.** When two
    objects could own a behaviour, pick the one that adds fewer
    dependencies and keeps its class about one thing. Fewer dependencies
    means fewer messages to other objects, fewer fields that exist only
    for that behaviour, and fewer reasons for the class to change. If
    both choices add the same dependencies, choose the object whose name
    best matches the behaviour.

## Pattern

Before, the use-case object `CancelAppointment` reads public fields
from `Appointment` and decides whether the booking can be cancelled.
After, `Appointment` owns that decision and the use-case object only
delegates.

Before:

```text
class Slot
  - patient: PatientId?
  + reserve(patientId: PatientId): void
    raises SlotTaken
    if patient = null then
      patient := patientId
    else
      raise SlotTaken
  + release(patientId: PatientId): void
    patient := null

class Appointment
  + slot: Slot
  + patient: PatientId
  + status: AppointmentStatus
  + cancellationReason: CancellationReason?
  + new(slot: Slot, patient: PatientId)
    status := Scheduled
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient)

class CancelAppointment
  + run(appointment: Appointment, reason: CancellationReason): void
    raises AppointmentNotCancellable
    if appointment.status = Scheduled then
      appointment.status := Cancelled
      appointment.cancellationReason := reason
      appointment.slot.release(appointment.patient)
    else
      raise AppointmentNotCancellable
    return
```

After:

```text
class Slot
  - patient: PatientId?
  + reserve(patientId: PatientId): void
    raises SlotTaken
    if patient = null then
      patient := patientId
    else
      raise SlotTaken
  + release(patientId: PatientId): void
    patient := null

class Appointment
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - cancellationReason: CancellationReason?
  - new(slot: Slot, patient: PatientId)
    status := Scheduled
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient)
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
      cancellationReason := reason
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return

class CancelAppointment
  + run(appointment: Appointment, reason: CancellationReason): void
    appointment.cancel(reason)
    return
```

`Appointment.book` reserves the slot, and the constructor sets the
status. Only `cancel` sets the reason and releases the slot. The
constructor is private, so `book` is the only way to create an
appointment. No field is read before it is set, and no step runs twice.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A method that reads two or more values from another object and then
  decides with them.
- A class named Manager, Processor or Handler whose methods touch
  unrelated parts of the domain.
- A request handler or controller that holds business conditions.
- A class whose version history shows changes for unrelated reasons.
- A constructor that takes many unrelated collaborators.

## Common mistakes

- Treating the object with the information as the object with the
  database row, then putting persistence into the domain object.
- Reading one reason to change as one method, then splitting a cohesive
  class into fragments.
- Moving every behaviour into services and leaving domain objects as
  data holders.
- Letting the use-case object accumulate business rules instead of
  delegating them.
- Inventing a service when an existing domain object could own the
  behaviour without losing cohesion.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.

## Further reading

- [Object roles](references/object-roles.md)
- [Extracting a class](references/extracting-a-class.md)
