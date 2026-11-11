---
name: oo-replacing-conditionals-with-polymorphism
description: Use when the same switch or if-chain on a type or status repeats across methods, or when choosing subclasses or pattern matching for cases.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Replacing Conditionals with Polymorphism

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A condition on a type code or a status is cheap to write once and costly
to repeat. Every copy is a place to forget when a case arrives, and the
copies drift until two of them disagree. This skill moves the choice into
objects that each answer for their own case, keeps the single place where
the code enters the system, and says when a lone conditional should stay.
It also chooses the shape of the case set by watching which side grows:
one subtype per case, or a closed set of cases that one exhaustive test
must cover.

## When to use

- The same condition on a kind, a type code or a status appears in two or
  more methods or classes.
- A method branches on a type code, and another method branches on the
  same code.
- An object's behaviour changes with its own status across several
  methods.
- A design choice is between one subtype per case and a closed set of
  cases that an exhaustive test handles.
- A class holds collaborators that only some of its cases use.
- Adding a case means editing code that already works in many files.

## When not to use

- The condition appears in one place, no copy of it exists, and its cases
  share their collaborators: leave it.
- The cases differ only in data, such as a duration or a label per kind:
  keep one class and look the value up in a table.
- The variation is an outside system, or a requirement that keeps
  changing behind one call: that is encapsulating what varies.
- A caller checks another object's status once and then changes that
  object: that is encapsulating state and behaviour.
- The condition is the one place where a stored code becomes an object.
  Rule 3 keeps it there on purpose.

## Core rules

1. Rule. **When the same condition on a type code or status appears in
   more than one method or class, give each case its own class behind one
   interface, and send the message instead of testing the code.** The
   condition is written once, where the object for the case is chosen, and
   every operation becomes a message that object answers. A new case is a
   new class, not another branch in every copy.

2. Default. **Leave a conditional that appears once where it is.** One
   branch in one place reads more directly than an interface and a class
   per case.

   The exception is a branch whose cases need different collaborators,
   such as one case that books a room and another that reserves a dose:
   give each case its own class even in one place, so no object holds
   collaborators that most of its cases never use.

3. Rule. **Choose the case once, where the type code enters the system,
   and pass the object from then on.** That place is where a stored row or
   a request is read. It may keep a conditional or a lookup table; no
   other code tests the code again.

4. Default. **When an object's behaviour changes with its own status in
   several methods, give each status its own object behind one interface
   and let the object delegate to its current one.** The object holds the
   current status object and sends it the messages for its actions.

   The exception is a status that gates only one or two methods: a check
   in those methods is clearer than a class per status.

5. Judgement. **Use a strategy when the choice comes from outside and
   stays fixed for the object's life, and a state when the object's own
   actions change it.** A strategy arrives through the constructor. A
   state object is replaced by the object it belongs to as its status
   changes.

6. Rule. **Keep one class when the cases differ only in values, such as a
   duration or a label per visit kind.** Look the value up in a table, and
   keep classes for cases that behave differently.

7. Judgement. **Choose subtypes when new kinds arrive more often than new
   operations, and a closed set of cases with exhaustive matching when new
   operations arrive more often than new kinds.** With subtypes, a new
   kind is one new class and a new operation edits every class. With a
   closed set, a new operation is one exhaustive test and a new kind edits
   every such test, which the compiler lists when the set is closed. A
   new kind also needs its entry where the stored code is read, which
   rule 3 keeps in one place. The version history shows which has been
   growing.

## Pattern

Before, `Visit` holds the kind, a room planner and a dose stock, and both
of its methods branch on the kind. The room planner serves only a
procedure and the dose stock only a vaccination, yet every visit holds
both. After, each kind is a class behind `VisitKind`, each holds only
what its own case needs, and `VisitKinds.fromCode` is the one place that
tests the stored code.

Before:

```text
enum VisitKind
  Consultation
  Procedure
  Vaccination

class Visit
  - kind: VisitKind
  - slot: Slot
  - roomPlanner: RoomPlanner
  - doseStock: DoseStock
  + new(kind: VisitKind, slot: Slot, roomPlanner: RoomPlanner,
      doseStock: DoseStock)
  + prepare(): void
    if kind = Procedure then
      roomPlanner.book(slot)
    else
      if kind = Vaccination then
        doseStock.reserve(slot)
      else
        return
    return
  + canBookOnline(patient: Patient): Boolean
    if kind = Consultation then
      return patient.hasPortalAccount()
    else
      if kind = Procedure then
        return patient.hasReferral()
      else
        return patient.isAdult()
```

`roomPlanner.book(slot)` is taken to book a room for the slot once,
`doseStock.reserve(slot)` to reserve one dose for it once, and
`patient.hasPortalAccount()`, `patient.hasReferral()` and
`patient.isAdult()` are each taken to answer a `Boolean` about that
patient. `true` is taken to mean the visit may be booked online and
`false` that it may not. Both methods read `kind`, which the constructor
sets before either runs, and each side effect happens once per call.

After:

```text
interface VisitKind
  + prepare(slot: Slot): void
    -- prepares what the kind needs once, and a kind that needs
    -- nothing may prepare nothing
  + canBookOnline(patient: Patient): Boolean

class Consultation implements VisitKind
  + new()
  + prepare(slot: Slot): void
    return
  + canBookOnline(patient: Patient): Boolean
    return patient.hasPortalAccount()

class Procedure implements VisitKind
  - roomPlanner: RoomPlanner
  + new(roomPlanner: RoomPlanner)
  + prepare(slot: Slot): void
    roomPlanner.book(slot)
    return
  + canBookOnline(patient: Patient): Boolean
    return patient.hasReferral()

class Vaccination implements VisitKind
  - doseStock: DoseStock
  + new(doseStock: DoseStock)
  + prepare(slot: Slot): void
    doseStock.reserve(slot)
    return
  + canBookOnline(patient: Patient): Boolean
    return patient.isAdult()

class Visit
  - kind: VisitKind
  - slot: Slot
  + new(kind: VisitKind, slot: Slot)
  + prepare(): void
    kind.prepare(slot)
    return
  + canBookOnline(patient: Patient): Boolean
    return kind.canBookOnline(patient)

class VisitKinds
  - roomPlanner: RoomPlanner
  - doseStock: DoseStock
  + new(roomPlanner: RoomPlanner, doseStock: DoseStock)
  + fromCode(code: String): VisitKind
    raises UnknownVisitKind
    if code = "C" then
      return new Consultation()
    else
      if code = "P" then
        return new Procedure(roomPlanner)
      else
        if code = "V" then
          return new Vaccination(doseStock)
        else
          raise UnknownVisitKind
```

`new Consultation()`, `new Procedure(roomPlanner)` and
`new Vaccination(doseStock)` are taken to build the kind for a code.
`"C"`, `"P"` and `"V"` are taken to be the stored codes for consultation,
procedure and vaccination. The code that reads a stored visit asks
`VisitKinds.fromCode` once and builds the `Visit` with the answer it
gets, so no other place tests the code. Each kind holds only its own
collaborator, set by its constructor before `prepare` reads it, and each
`prepare` makes its side effect once. `Consultation` holds nothing and
prepares nothing, which the contract comment on `VisitKind.prepare`
allows. `Visit` holds only `kind` and `slot`, so neither a room planner
nor a dose stock reaches a case that does not use it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- The same `if` chain or switch on one type code or status in two or
  more methods.
- A `kind`, `type` or `status` field read mostly to choose behaviour.
- A default branch that raises an unknown-type error in several places.
- An object that holds collaborators only some of its cases use.
- A new enumeration member that needs edits in many files.

## Common mistakes

- A class per case when the cases differ only in a value.
- Testing the code again after the object for its case was chosen.
- An interface and classes for a conditional that appears once and whose
  cases share their collaborators.
- Subtypes on an axis that grows by operations, so every new operation
  edits every class.
- Keeping the old conditional beside the new classes, so the two drift
  apart.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-what-varies](../oo-encapsulating-what-varies/SKILL.md)
  finds the seam that a new case would use.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps a status object behind the actions that change it.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  makes each kind keep the interface contract it implements.

## Further reading

- [State and strategy](references/state-and-strategy.md)
- [Subtypes or matching](references/subtypes-or-matching.md)
