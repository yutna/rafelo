---
name: oo-modeling-values-and-entities
description: Use when picking value or entity, when ids are raw strings or numbers, when editing one object changes another, or equal objects compare unequal.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Modeling Values and Entities

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Every domain concept is either a value or an entity, and the choice
decides how it behaves. A value is interchangeable with any other value
of the same contents, so it never changes and compares by those
contents. An entity is one thing with a history, so it carries an
identifier that never changes and compares by that identifier. This
skill makes the choice, turns ruled primitives into value types, and
keeps the two kinds from borrowing each other's rules.

## When to use

- A new concept needs a type, and it is unclear whether two instances
  with the same contents are the same thing.
- An identifier travels as a raw string or number, or two identifiers
  of the same primitive type sit side by side.
- Editing one object changes another object that holds the same
  instance.
- Two objects with equal contents compare unequal, or a set or a map
  cannot find the one that is equal.
- The same format, range or unit check on a raw value appears in several
  places.
- A concept has few fields, and someone argues it must therefore be a
  value.

## When not to use

- The type only carries data across a process or layer boundary, and no
  rule depends on its equality. Keep it a plain data transfer object and
  convert it at the edge. That is deciding object or data.
- The question is whether the type needs a class at all, or should stay
  a record or a map. Decide that first with deciding object or data.
- The primitive has no rule of its own and one use, such as a free-text
  note. Leave it as it is.

## Core rules

1. Rule. **Decide value or entity with one question: are two instances
   with the same contents the same thing?** If yes, it is a value: two
   30-minute durations are interchangeable. If no, it is an entity: two
   clinicians with the same surname are two clinicians, and a clinician
   whose surname changes is still the same clinician.

2. Rule. **Make a value immutable.** An operation that would change it
   returns a new value. A value can then be shared without a copy, and
   no holder ever sees another holder's change.

3. Rule. **Compare a value by all of its contents, and keep equality,
   hashing and any ordering in agreement.** Two equal values hash alike,
   and an ordering ranks two values as equal exactly when they are
   equal. In the notation `value` gives this equality; how a language
   provides it belongs to the language packs.

4. Rule. **Give an entity an identifier that is assigned once, when it
   is created or first stored, and never changes.** Compare two entities
   by that identifier, never by their other attributes, which change
   over the entity's life.

5. Default. **Replace a primitive that carries a domain rule with a
   value type.** A raw string or number with a format, a range or a unit
   repeats its check at every use, and two such parameters can be
   swapped without an error. A value type checks the rule once, when it
   is built, and turns the swap into a type error.

   The exception is a primitive with no rule of its own and one use,
   such as a free-text note: a type around it adds a name and protects
   nothing.

6. Default. **Put behaviour that needs only a value's contents on the
   value.** Adding two fees in one currency belongs to the fee.

   The exception is an operation that needs a collaborator a value must
   not hold, such as a currency rate service: keep it in a service that
   takes the value.

7. Judgement. **The same concept can be a value in one part of the
   system and an entity in another; decide by what that part tracks.** A
   room is a value on an appointment letter and an entity for the team
   that tracks its equipment and repairs.

## Pattern

Before, `Referral` takes two strings and `ReferralDesk.refer` passes
them in the wrong order. Both parameters are `String`, so the swap
compiles and files the clinician as the patient.

Before:

```text
class Referral
  - patient: String
  - clinician: String
  + new(patient: String, clinician: String)

class ReferralDesk
  + refer(patient: String, clinician: String): Referral
    return new Referral(clinician, patient)
```

After, `PatientId` and `ClinicianId` are values. Each checks its format
once, in its constructor, and raises an error that names the broken
rule. `text.hasPatientIdFormat()` and `text.hasClinicianIdFormat()` are
taken to mean true when the text matches that identifier's format.

After:

```text
value PatientId
  - patientId: String
  + new(text: String)
    raises MalformedPatientId
    if text.hasPatientIdFormat() then
      patientId := text
    else
      raise MalformedPatientId

value ClinicianId
  - clinicianId: String
  + new(text: String)
    raises MalformedClinicianId
    if text.hasClinicianIdFormat() then
      clinicianId := text
    else
      raise MalformedClinicianId

class Referral
  - patient: PatientId
  - clinician: ClinicianId
  + new(patient: PatientId, clinician: ClinicianId)

class ReferralDesk
  + refer(patient: PatientId, clinician: ClinicianId): Referral
    return new Referral(patient, clinician)
```

`Referral` now takes the two types, so the old call,
`new Referral(clinician, patient)`, is a type error: a `ClinicianId` is
not a `PatientId`. `ReferralDesk.refer` passes each identifier in its
own position. A factory would add nothing here, because each identifier
has one field and one way to be made.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A method that changes a field of an object that other objects also
  hold.
- Two or more parameters of the same primitive type side by side, such
  as two strings for two different identifiers.
- The same format or range check on a raw string or number in several
  places.
- An entity compared by its name, phone number or other attributes that
  change.
- A value type with a setter, or equality written without matching
  hashing.

## Common mistakes

- Making an entity a value because it has few fields: a patient with
  only a name is still an entity.
- Wrapping every primitive, including ones with no rule and one use.
- Comparing entities by all their fields, so an edited copy no longer
  equals the stored one.
- Using an attribute that can change as the identifier, such as a phone
  number as the patient's key.
- Copying an immutable value defensively, which buys nothing.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes the task and defines the
  rule labels.
- [oo-deciding-object-or-data](../oo-deciding-object-or-data/SKILL.md)
  decides whether a concept needs a class at all, before this skill
  picks a value or an entity.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  builds an identifier with one constructor that rejects malformed text.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps an entity's state behind messages and says when a mutable value
  crosses a boundary as a copy.

## Further reading

- [Equality and identity](references/equality-and-identity.md)
- [Immutable values](references/immutable-values.md)
