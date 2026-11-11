---
name: oo-limiting-what-an-object-knows
description: Use when code reaches through a chain of objects, when a method works mostly on another object's data, or when a class only forwards calls.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Limiting What an Object Knows

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An object that reaches through another object to its collaborator depends
on a structure it does not own. This skill keeps each method talking to
its own fields, its parameters and the objects it creates, sends a
request to the nearest object that can answer it, deletes a class that
only forwards, and moves a method to the object whose data it uses most.
A change to one object's shape then stops at that object's neighbours
instead of spreading to every caller that walked through it.

## When to use

- A method sends a message to an object that another message returned.
- A test has to build three or four objects so the code under test can
  walk through them.
- A method sends most of its messages to one object and reads little of
  its own data.
- Most methods of a class forward to one collaborator, and the class adds
  no rule of its own.
- One answer in a caller needs the shape of several objects in a row.
- A change to one object's internals breaks a caller that never held it.

## When not to use

- The chain only reads values or a plain data structure, such as a data
  transfer object or a configuration, and no behaviour is hidden behind
  it.
- A caller reads an object's state and then changes it: that is a
  getter-check-set sequence, and `oo-encapsulating-state-and-behaviour`
  replaces it with a message.
- The question is which class should own a new behaviour, before any code
  reaches through objects: that is `oo-assigning-responsibilities`, which
  starts from the data a behaviour needs.
- Many classes change together across modules and the question is how
  tightly they are tied: that is `oo-diagnosing-coupling`, which measures
  the tie before it is loosened.

## Core rules

1. Default. **Send a message only to the object itself, to its fields, to
   its parameters or to an object it creates.** A method that sends a
   message to the result of another message depends on a structure it
   does not own: the returned object can change, and the caller's code
   still names it. Stop at the object you hold or were handed.

   The exception is a value or a plain data structure. Reading
   `appointment.startsAt().date()` depends on the public meaning of a
   value, not on another object's structure, so that read needs no new
   message on the appointment.

2. Rule. **When a caller reaches through an object to one of its
   collaborators, give the nearest object a message that answers what the
   caller wants.** Name the request in the caller's words and let the
   object decide how to answer it. Each object then talks only to its
   neighbours, and a change to one object's structure stops there.

3. Default. **Remove a middle man: when most of a class's methods only
   forward to one collaborator, let callers hold the collaborator.** A
   class that adds no rule and repeats its collaborator's messages grows a
   method for every feature the collaborator gains. Delete it and pass the
   collaborator to the callers that need it.

   The exception is a class that forwards on purpose to hide a boundary,
   such as an adapter in front of an outside system or the one entry point
   a module publishes. Its forwards keep the outside shape away from the
   rest of the code.

4. Judgement. **Hiding a delegate and removing a middle man pull in
   opposite directions; decide by which change you want to contain.** Hide
   the delegate when the collaborator's structure is likely to change
   under many callers, so that one class absorbs the change. Remove the
   middle man when its forwarding methods grow with every new feature of
   the collaborator, so that the growth lands on the collaborator's own
   callers instead of on one more shell.

5. Rule. **Move a method to the object whose data it uses most.** A method
   that sends most of its messages to one other object, and reads little
   of its own, belongs on that object. The move removes the chain that fed
   the method, because it can then read the data where the data lives.

6. Default. **Give a method the object it works on, not a larger object it
   must dig through.** A label printer that needs a patient's name takes
   the name, not the appointment. Every caller then passes only what the
   method uses, and the method cannot grow a dependency on the rest of the
   larger object.

   The exception is a method that needs several parts of the larger
   object. Passing each part separately would tie every caller to the
   method's insides, so the whole object is then the smaller contract.

## Pattern

Before, `InvoiceWriter.lineFor` walks from the appointment to its slot,
from the slot to its clinician and from the clinician to the rates to ask
for a fee, then walks to the slot again for the length. The writer
depends on the structure of three objects it does not hold.

Before:

```text
class InvoiceWriter
  + lineFor(appointment: Appointment): InvoiceLine
    return new InvoiceLine(appointment.date(),
      appointment.slot().clinician().rates().feeFor(
        appointment.kind(), appointment.slot().length()))

class Appointment
  - slot: Slot
  - patient: PatientId
  - kind: AppointmentKind
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, kind: AppointmentKind,
      status: AppointmentStatus)
  + date(): Date
    return slot.date()
  + slot(): Slot
    return slot
  + kind(): AppointmentKind
    return kind

class Slot
  - clinician: Clinician
  - startsAt: DateTime
  - length: Duration
  - patient: PatientId?
  - new(clinician: Clinician, startsAt: DateTime,
      length: Duration, patient: PatientId?)
  + date(): Date
    return startsAt.date()
  + clinician(): Clinician
    return clinician
  + length(): Duration
    return length

class Clinician
  - rates: Rates
  - new(rates: Rates)
  + rates(): Rates
    return rates

value Rates
  - priceList: List<Rate>
  + new(entries: List<Rate>)
    priceList := entries.copy()
  + feeFor(kind: AppointmentKind, length: Duration): Fee
    return priceList.feeFor(kind, length)

value Rate
  - kind: AppointmentKind
  - length: Duration
  - fee: Fee
  + new(kind: AppointmentKind, length: Duration, fee: Fee)

enum AppointmentKind
  Consultation
  Procedure
```

Of the results in that chain, `slot()` and `clinician()` are objects with
behaviour. Sending `clinician()` to the slot, `rates()` to the clinician
or `length()` to the slot reaches through an object the writer does not
hold; the answer being a value does not make that send safe. `rates()`
returns a `Rates` value, so sending `feeFor` to it is the exception rule 1
allows, and `kind()` is sent to the writer's own parameter. `kind()`,
`length()` and `feeFor` answer values: an `AppointmentKind`, a `Duration`
and a `Fee`.

After, `lineFor` sends the appointment two messages, `date()` and
`fee()`, the two parts of the appointment it bills. `Appointment.fee`
sends `slot.feeFor(kind)` with its own `kind`; `Slot.feeFor` sends
`clinician.feeFor(kind, length)` with its own `length`; and
`Clinician.feeFor` sends `rates.feeFor(kind, length)`. Each object adds
what it holds and talks only to its own fields and parameters. Every fee
method sends one message; `Clinician.feeFor` is the one plain forward in
the fee path, kept on purpose under rule 4. The invoice, the booking
screen and the quote letter all ask a clinician for a fee, and where a
clinician's rates live has changed twice this year, so the next change
stops at `Clinician`.

After:

```text
class InvoiceWriter
  + lineFor(appointment: Appointment): InvoiceLine
    return new InvoiceLine(appointment.date(), appointment.fee())

class Appointment
  - slot: Slot
  - patient: PatientId
  - kind: AppointmentKind
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, kind: AppointmentKind,
      status: AppointmentStatus)
  + date(): Date
    return slot.date()
  + fee(): Fee
    return slot.feeFor(kind)

class Slot
  - clinician: Clinician
  - startsAt: DateTime
  - length: Duration
  - patient: PatientId?
  - new(clinician: Clinician, startsAt: DateTime,
      length: Duration, patient: PatientId?)
  + date(): Date
    return startsAt.date()
  + feeFor(kind: AppointmentKind): Fee
    return clinician.feeFor(kind, length)

class Clinician
  - rates: Rates
  - new(rates: Rates)
  + feeFor(kind: AppointmentKind, length: Duration): Fee
    return rates.feeFor(kind, length)

value Rates
  - priceList: List<Rate>
  + new(entries: List<Rate>)
    priceList := entries.copy()
  + feeFor(kind: AppointmentKind, length: Duration): Fee
    return priceList.feeFor(kind, length)

value Rate
  - kind: AppointmentKind
  - length: Duration
  - fee: Fee
  + new(kind: AppointmentKind, length: Duration, fee: Fee)

enum AppointmentKind
  Consultation
  Procedure
```

`Slot` in this example holds the `Clinician` object it is with, where the
notation's illustration holds a `ClinicianId`; the fence declares the
field it uses. `length` is a `Duration` value, not a number of minutes.
Every fee method returns the `Fee` value with an amount and a currency,
never a bare number. `startsAt.date()` is taken to mean the calendar date
of that start time, and `priceList.feeFor(kind, length)` is taken to mean the
fee the price list holds for that kind and length. `Appointment.date` and
`Slot.date` answer a value along one field each, so they add no structure
of their own. Neither fence shows how a `Slot` or a `Clinician` is made;
both leave out the method that calls each private constructor.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A line with several messages in a row, each sent to what the one before
  returned, when those results are objects with behaviour.
- A test that must build several objects only so the code under test can
  walk through them.
- A class whose methods are mostly one-line forwards to the same
  collaborator.
- A method that reads more of another object's data than its own.
- A parameter used only to reach one of its parts.

## Common mistakes

- Counting dots instead of asking whose structure a chain depends on: a
  chain of value queries is fine.
- Hiding every delegate, so each class grows a forwarding method for each
  feature of its collaborators.
- Removing an adapter or an entry point that hides a boundary on purpose.
- Moving a method next to its data but leaving the old method behind as a
  forward.
- Fixing a chain by storing a copy of the far object's data, which then
  goes stale.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  chooses the class that owns a behaviour and its data.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps state behind messages that name the action.
- [oo-diagnosing-coupling](../oo-diagnosing-coupling/SKILL.md) measures
  how tightly two parts are tied when many classes change together.

## Further reading

- [Delegates and middle men](references/delegates-and-middle-men.md)
