---
name: oo-making-illegal-states-impossible
description: Use when flags or optional fields allow forbidden states, such as accepted and declined at once, or a reason set when nothing was cancelled.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Making Illegal States Impossible

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A type should allow exactly the values the domain has. A class that
carries a boolean per stage and an optional field per stage detail
multiplies those possibilities: three optional fields allow eight
combinations for a prescription with four states, and nothing in the
type says which combinations are real. This skill replaces the flags
with one type per state, each holding only that state's data, closes
the set where the domain closes it, and moves rules into the types that
can enforce them. An action then exists only on the state that allows
it, so an impossible combination has no way to be built.

## When to use

- Two or more booleans on one class describe stages of one lifecycle.
- An optional field is set only in some states, or a comment beside the
  fields says "never both".
- A method opens by rejecting a combination that should never exist.
- A type admits values the domain never has, such as an appointment
  request that is accepted and declined at once.
- A rule that only reads a value's own fields is checked at every call
  site instead of once, when the value is built.
- A stored record holds a combination the code calls impossible.
- A new state arrives, and every place that branches on the old fields
  must be found by hand.

## When not to use

- The rule depends on other objects or on time, such as whether a slot
  is free now. Check it where the action happens, as
  [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  describes.
- The question is how to build an object whose states are already
  settled, with a constructor, a factory or a builder. That belongs to
  [constructing valid objects](../oo-constructing-valid-objects/SKILL.md).
- The cases differ in behaviour, and the question is whether to use
  subtypes or exhaustive matching as kinds and operations grow. That is
  [replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md).
- The data crosses a process boundary as a plain record. That is
  [deciding object or data](../oo-deciding-object-or-data/SKILL.md).

## Core rules

1. Rule. **Make every value a type allows a state the domain allows.**
   When flags and optional fields are meaningful only in some
   combinations, replace them with one type per real state. Each type
   holds exactly the data its state has, and no other state's data. The
   type then has no value that stands for a state the clinic never has.

2. Rule. **Close the set of states where the domain closes it.** Mark
   the state types as a closed set; in the notation a `--` comment does
   that, and the language packs name the keyword. A new state is then a
   deliberate edit to the set, and every exhaustive test over the set
   must handle it before the code builds.

3. Default. **Carry a rule in a type before writing a check for it.** A
   duration that cannot be negative, or a time range whose end follows
   its start, is built only through a constructor that refuses a broken
   value. Every holder then knows the rule holds, and no call site
   repeats it.

   The exception is a rule that depends on other objects or on time,
   such as whether a slot is free now. Check it where the action
   happens.

4. Judgement. **Choose between an enumeration and a class per state by
   the data the states carry.** States that carry the same data, or no
   data, fit an enumeration, with behaviour per member where the
   language allows it. States that carry different data need a class
   each. What tips the balance is whether any state has a field the
   others lack.

5. Judgement. **Offer an action only on the state that allows it when
   callers hold the state itself.** When callers hold the entity and its
   status changes over its life, keep a status object inside the entity
   and replace the conditionals with polymorphism. What tips the balance
   is what the caller holds: with the state in hand, an action the state
   lacks is a message its type does not answer, not a check that fails
   at run time.

6. Default. **Make each state's data required.** A field that is
   optional only because some states lack it belongs to the types of the
   states that have it. The state that has the field then always has a
   value for it.

   The exception is a field the domain treats as optional in every
   state, such as a free-text note.

## Pattern

Before, `Prescription` holds three optional fields beside the three
that every prescription has. The optional fields allow eight
combinations, while a prescription has four states, and nothing stops
`dispense` on one nobody issued or `cancel` on one already dispensed.

Before:

```text
class Prescription
  - id: PrescriptionId
  - patient: PatientId
  - medicine: Medicine
  - issuedBy: ClinicianId?
  - dispensedOn: Date?
  - cancelReason: CancellationReason?
  + new(id: PrescriptionId, patient: PatientId, medicine: Medicine)
    issuedBy := null
    dispensedOn := null
    cancelReason := null
  + issue(by: ClinicianId): void
    issuedBy := by
    return
  + dispense(on: Date): void
    dispensedOn := on
    return
  + cancel(reason: CancellationReason): void
    cancelReason := reason
    return
```

After, four values form a closed set behind `interface Prescription`.
Each holds only its own state's data, every field is required, and the
three actions each return a new value.

After:

```text
interface Prescription
  -- closed: these four states are the only prescriptions
  + medicine(): Medicine

value DraftPrescription implements Prescription
  - id: PrescriptionId
  - patient: PatientId
  - medicine: Medicine
  + new(id: PrescriptionId, patient: PatientId, medicine: Medicine)
  + medicine(): Medicine
    return medicine
  + issue(by: ClinicianId): IssuedPrescription
    return new IssuedPrescription(id, patient, medicine, by)

value IssuedPrescription implements Prescription
  - id: PrescriptionId
  - patient: PatientId
  - medicine: Medicine
  - issuedBy: ClinicianId
  + new(id: PrescriptionId, patient: PatientId, medicine: Medicine,
      issuedBy: ClinicianId)
  + medicine(): Medicine
    return medicine
  + dispense(on: Date): DispensedPrescription
    return new DispensedPrescription(id, patient, medicine, issuedBy, on)
  + cancel(reason: CancellationReason): CancelledPrescription
    return new CancelledPrescription(id, patient, medicine, issuedBy,
      reason)

value DispensedPrescription implements Prescription
  - id: PrescriptionId
  - patient: PatientId
  - medicine: Medicine
  - issuedBy: ClinicianId
  - dispensedOn: Date
  + new(id: PrescriptionId, patient: PatientId, medicine: Medicine,
      issuedBy: ClinicianId, dispensedOn: Date)
  + medicine(): Medicine
    return medicine

value CancelledPrescription implements Prescription
  - id: PrescriptionId
  - patient: PatientId
  - medicine: Medicine
  - issuedBy: ClinicianId
  - reason: CancellationReason
  + new(id: PrescriptionId, patient: PatientId, medicine: Medicine,
      issuedBy: ClinicianId, reason: CancellationReason)
  + medicine(): Medicine
    return medicine
```

The identifier `id` keeps two prescriptions two prescriptions when
they share a patient and a medicine, as the values skill's rules 1 and
4 require. `medicine()` answers the one field every state holds.
`issue` returns an `IssuedPrescription`, `dispense` a
`DispensedPrescription`, and `cancel` a `CancelledPrescription`; no
method assigns to a field, so no state changes after its constructor.
`DraftPrescription` offers `issue` as its only action,
`IssuedPrescription` offers `dispense` and `cancel`, and the two end
states offer neither `dispense` nor `cancel`, so a message a state does
not allow has no method to land on. The `--` comment marks the set
closed. The constructor parameters are named for their fields, so each
constructor sets every field before any action reads it.
`CancellationReason` is the notation's value for why an appointment was
cancelled, and the same value serves a prescription here. The
constructing skill's builder holds a `Prescription` as one optional part
of a report; here the same name is the interface over the four states.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- Two or more booleans on one class that describe one lifecycle.
- An optional field that is set only in some states.
- A check at the top of a method for a combination that should never
  happen.
- A comment such as "never both" or "only when cancelled" beside
  fields.
- An enumeration member that needs data the other members lack.

## Common mistakes

- Adding a check for an impossible combination instead of removing the
  combination.
- A class per state for states that carry the same data, where an
  enumeration says it.
- Leaving the set of states open, so a new state skips the places that
  must handle it.
- Giving a state type a setter that turns it into another state.
- Putting a rule about other objects or about time into a type, where
  it goes stale.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  builds the object once its shape is chosen.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)
  keeps the identifier and the value immutable.
- [oo-replacing-conditionals-with-polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  gives a status object to an entity whose status changes.

## Further reading

- [States as types](references/states-as-types.md)
- [Rules in types](references/rules-in-types.md)
