---
name: oo-constructing-valid-objects
description: Use when an object can exist half-built, needs setup calls after its constructor, takes a long parameter list, or needs a factory or builder.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Constructing Valid Objects

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An object is built once and used many times. If it leaves its
constructor incomplete, every caller carries the missing step, and one
caller that forgets leaves the object in a state its rules forbid. This
skill keeps construction in one place: a constructor, a named factory or
a builder, chosen for the number of ways the object can arrive and the
number of optional parts it carries. The result is an object that is
valid the moment it exists.

## When to use

- An object needs an `init` method or a run of setters before it can
  answer a message.
- A constructor takes so many arguments that callers count positions.
- Creation has several names, such as booking a first visit and booking
  a follow-up, and one constructor hides the difference.
- A class asks for a collaborator it builds itself instead of receiving
  it.
- A builder has appeared for an object with a field or two.
- A design review asks how a new object should be built and checked.

## When not to use

- A framework builds the object through a no-argument constructor for
  its mapping. Let the framework map at the edge, and validate where the
  data enters instead.
- The question is which class should create the object, not how the
  object is built. That question belongs to assigning
  responsibilities.
- The object has one or two required fields and one way to be made. A
  plain constructor is enough.

## Core rules

1. Rule. **A constructor leaves the object complete and valid.**
   Every field is set and every invariant is true when the constructor
   returns. No instance exists in a state its rules forbid, so no caller
   has to finish the job.

2. Rule. **Nothing is required between creation and use.**
   Do not ship an `init` method or a run of setters that a caller must
   send before the object answers its messages. A caller that receives
   the object can use it at once.

3. Rule. **Reject invalid input at the moment the object is built, with
   an error that names the broken rule.** A generic failure hides which
   rule failed, and the caller cannot tell a typo from a rule the clinic
   changed. The constructor, factory or build step raises the named
   error before the object is handed out.

4. Default. **Give each way of creating the object its own named
   factory.** Use one when the object has several ways to come into
   being, when creation may return an instance that already exists, or
   when it chooses among subtypes. The factory's name says which way,
   such as `forNewPatient` or `followUp`, so a caller reads the intent
   without counting arguments.

   The exception is an object with one obvious way to be made and one
   or two required fields: a plain constructor is enough, and a factory
   adds only a name to learn.

5. Rule. **Use a builder only when many parts are optional.** Put the
   required parts in the builder's own constructor, give each optional
   part a command that returns nothing, and let the step that builds
   check the whole before it returns the object.

6. Rule. **Build the objects the class owns; receive every collaborator
   it uses.** A class may create the value objects and the parts that
   live and die with it. A repository, a clock, a notifier or another
   service arrives through the constructor, so the class can be given a
   different one in a test or in another clinic.

## Pattern

Before, a booking desk reserves the slot and then calls a five-argument
constructor. `null` says there is no previous visit, `false` says this
is not a follow-up, and `30` is the length of the visit in minutes.
Nothing in the call says which kind of appointment is being made, and a
caller that passes `true` with `null` gets a follow-up with no previous
visit.

Before:

```text
class BookingDesk
  + book(patient: PatientId, slot: Slot): Appointment
    slot.reserve(patient)
    return new Appointment(patient, slot, null, false, 30)

class Appointment
  - patient: PatientId
  - slot: Slot
  - previousVisit: Appointment?
  - followUp: Boolean
  - duration: Minutes
  + new(patient: PatientId, slot: Slot, previousVisit: Appointment?,
      followUp: Boolean, duration: Minutes)
```

After, the constructor is private, so only code inside `Appointment`
can call it, and only the two factories do. `forNewPatient` reserves
the slot once and builds
an appointment with no previous visit. `followUp` first asks whether the
previous visit belongs to this patient, and only then reserves the
slot, once. A refused follow-up raises `NotThisPatientsVisit` before
anything is reserved. Both factories set all five fields before they
return, and they are the only callers of the constructor, so the
follow-up flag and the previous visit cannot disagree.

After:

```text
class BookingDesk
  + book(patient: PatientId, slot: Slot): Appointment
    return Appointment.forNewPatient(patient, slot)

class Appointment
  - patient: PatientId
  - slot: Slot
  - previousVisit: Appointment?
  - followUp: Boolean
  - duration: Minutes
  - new(patient: PatientId, slot: Slot, previousVisit: Appointment?,
      followUp: Boolean, duration: Minutes)
  + patient(): PatientId
    return patient
  + static forNewPatient(patient: PatientId, slot: Slot): Appointment
    slot.reserve(patient)
    return new Appointment(patient, slot, null, false, 30)
  + static followUp(patient: PatientId, previous: Appointment,
      slot: Slot): Appointment
    raises NotThisPatientsVisit
    if previous.patient() = patient then
      slot.reserve(patient)
      return new Appointment(patient, slot, previous, true, 30)
    else
      raise NotThisPatientsVisit
```

`BookingDesk.book` hands the reservation to the factory and has no
other step. The private constructor is reached only from the two
factories in the fence.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- An `init` method, or a run of setters, called right after `new`.
- A field that stays `null` until something sets it later.
- A constructor that reads a file, calls the network or queries the
  database.
- Several constructors that differ only in how many arguments they
  take.
- A builder for an object with two fields.

## Common mistakes

- Checking a rule in every method instead of once at construction, so
  one method will eventually forget it.
- A builder whose `build` returns the object without checking the parts
  it collected.
- Factory names such as `create` or `make` that say nothing about which
  way the object is made.
- Raising a generic error that does not name the broken rule.
- A class that creates its own repository or notifier instead of
  receiving one.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  chooses the class that owns a creation decision.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps the rules about the state the object is built with.

## Further reading

- [Factories and builders](references/factories-and-builders.md)
