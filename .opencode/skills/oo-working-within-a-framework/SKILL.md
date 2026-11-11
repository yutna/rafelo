---
name: oo-working-within-a-framework
description: Use when a framework wants domain classes to extend its base class, offer setters or carry its markers, or deciding how far to go along with it.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Working Within a Framework

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A framework offers places for code: a base class its mapper saves, a
hook before each save, a setter its binder fills, a marker its container
reads. Each offer is convenient, and none of them is a home for a
business rule. This skill keeps every rule and invariant in the domain,
meets the framework in a class at the edge that converts once, weighs
the demands rule 2 leaves open by whether they reach a rule, and records
each choice once for the code base. Where the framework is built of
functions and components, the clinic's rules still get a module of their
own.

## When to use

- A framework asks the clinic's domain classes to extend its base class.
- A form binder wants a setter for each field, or a container wants to
  build an object the domain owns.
- A rule sits in a controller, a save hook, a callback or a validation
  marker.
- The team is deciding how far to follow a framework, and where to stop.
- The same framework demand is met a different way in two modules.
- A framework built of functions and components holds clinic rules.

## When not to use

- The part being changed uses no framework type, such as a domain module
  that imports nothing from the framework: the other skills apply
  directly.
- The question is only whether one module uses active records or a data
  mapper: that is
  [taming persistence](../oo-taming-persistence/SKILL.md).
- The question is how a screen's state and its logic are split from the
  domain: that is
  [separating presentation from domain](../oo-separating-presentation-from-domain/SKILL.md).
- The question is how one named framework's own features are called and
  configured: outside this skill.

## Core rules

1. Rule. **Keep every business rule and every invariant in the domain,
   whatever place the framework offers for it: no rule moves into a
   controller, a save hook, a callback or a validation marker, and no
   domain object can be stored in a state the clinic forbids.** A place
   the framework offers is still a place in the code, not a licence to
   break a rule. The index's labels settle what that costs: no framework
   excuses a rule labelled `Rule.`, as
   [how strictly a rule is meant](../oo-design/SKILL.md#how-strictly-a-rule-is-meant)
   says.

2. Default. **Meet a framework's demand in a class at the edge that the
   framework shapes, such as a form object, a mapped row or a request
   handler, and convert it to the domain's types in one place there.**
   [Deciding object or data](../oo-deciding-object-or-data/SKILL.md)
   rule 3 converts a transfer object once, and
   [placing domain logic](../oo-placing-domain-logic/SKILL.md) rule 5
   turns text into values at the edge and leaves what is allowed to the
   domain. Where a mapper cannot rebuild a domain class through the
   class's own factory, it maps a separate stored record and the adapter
   converts that, as
   [taming persistence](../oo-taming-persistence/SKILL.md) rule 2 asks.
   The exception is a module that
   [taming persistence](../oo-taming-persistence/SKILL.md) rule 1 puts
   on active records, because its classes mirror their tables and hold
   few rules: there the framework's class is the module's class.

3. Judgement. **Weigh each demand rule 2 does not settle by what it
   would cost the domain.** Rule 2 settles where a framework base class
   goes. When a class holds rules, the base class goes on a class at
   the edge, unless taming persistence rule 1 puts the module on active
   records: there the module's own classes hold few rules and carry it.
   Rule 3 does not weigh that choice again. The demand for a base class
   on a mapped row, and the demand for a marker on a request handler,
   are met in an edge class rule 2 names, so rule 3 does not weigh them
   either. For the demands left, accept one that touches only the edge:
   a container that builds the objects the framework builds, as
   [patterns the language provides](../oo-patterns-the-language-provides/SKILL.md)
   rule 6 allows. Refuse a demand that moves a rule out of the domain,
   lets an object exist in a state the clinic forbids, hands a container
   to domain code, which
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rule
   5 forbids, or leaves a domain method working only while the
   framework's session is open, which
   [taming persistence](../oo-taming-persistence/SKILL.md) rule 5
   forbids. What tips the balance is whether the demand reaches a rule
   or a domain object's messages: going along costs one conversion at
   the edge, while fighting the framework where nothing in the domain is
   at stake costs code that every later change must carry.

4. Default. **Decide once for the whole code base how it meets each
   framework demand, write that one decision down as a decision record,
   as documenting design decisions, rule 1, asks of a choice that is
   costly to reverse, and meet the demand the same way in every module.**
   Once means once for the code base, not once for each module: rule 2's
   exception for a module on active records is part of that same
   decision, so which modules it covers is settled there, not by a
   second choice in each module. A second module that meets the same
   demand another way is a second design that every later reader must
   learn.
   The exception is a demand that only one module meets, such as the
   scheduler that only the reminders module uses: decide it in that
   module.

5. Default. **In a framework built of functions and components rather
   than classes, keep the clinic's rules in a module of their own that
   the components call, and write that module in the idiom the code
   around it uses, as patterns the language provides, rule 7, asks:
   never force classes into code built of functions.** The module
   imports nothing from the framework, so a test calls it with plain
   values and no screen. Where the code base is built of functions, the
   module is built of functions over values too.
   The exception is screen logic, such as which button is enabled, which
   [separating presentation from domain](../oo-separating-presentation-from-domain/SKILL.md)
   rule 2 keeps in what holds the screen's state, where a test can drive
   it, rather than in the domain.

## Pattern

`HomeReading` is one blood-pressure reading a patient takes at home.
`FrameworkRecord` is taken to be the framework's base class for the
objects its mapper saves, and it sends `beforeSave` to the object before
each save.

Before:

```text
class HomeReading extends FrameworkRecord
  - patient: PatientId
  - pressure: BloodPressure
  - flagged: Boolean
  + new(patient: PatientId, pressure: BloodPressure)
    flagged := false
  + beforeSave(): void
    if pressure.isHigh() then
      flagged := true
  + needsReview(): Boolean
    return flagged
```

In the Before, the rule that a high reading needs review lives in that
hook, so `needsReview()` answers `false` for a high reading until the
framework saves it, and a reading stored by any path that skips the hook
is never flagged (rule 1).

After:

```text
class HomeReading
  - patient: PatientId
  - pressure: BloodPressure
  + new(patient: PatientId, pressure: BloodPressure)
  + needsReview(): Boolean
    return pressure.isHigh()
```

In the After, `needsReview()` keeps the rule from the moment the reading
is built, and `HomeReading` extends nothing of the framework. The
framework's base class goes on a row class at the edge, converted to and
from `HomeReading` in one adapter, as
[taming persistence](../oo-taming-persistence/SKILL.md) rule 2 keeps
every mapping decision there; the row class and the adapter are left out
of the fence (rule 2).
The base class on the row is the edge class rule 2 asks for, and the
hook is refused because it reaches a rule (rule 3).

`BloodPressure` is taken to be a value whose `isHigh()` answers whether
the reading is above the clinic's level for review. `true` and `false`
are the two values a `Boolean` holds. `patient` is set by the constructor
and read by neither fence.

The fences store nothing, and the use case that stores a reading through
its repository, in the transaction it opens and ends, is left out. In the
Before, `flagged` is set before `needsReview` reads it; in the After,
`needsReview` reads only the fields its constructor set.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A business rule in a save hook, a callback or a controller.
- A domain class that extends a framework's base class or carries its
  markers.
- A domain class that asks a container for a collaborator.
- A domain method that fails once the framework's session has closed.
- The same framework demand met a different way in each module.
- Classes written into a module whose code is built of functions.

## Common mistakes

- Moving a rule into the place the framework offers because the place
  is there.
- Wrapping every framework call in an interface of the team's own when
  no rule is at stake.
- Letting a form binder fill domain objects field by field.
- Deciding the same framework demand again in every pull request.
- Rewriting screen code built of functions into classes.

## Related skills

- [oo-design](../oo-design/SKILL.md)
  sizes a task and defines the three rule labels.
- [oo-taming-persistence](../oo-taming-persistence/SKILL.md)
  rules 1, 2 and 5, for active records, the adapter's mapping and lazy
  loading.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  rule 5, and rule 4's exception, for a container and the composition
  root.
- [oo-deciding-object-or-data](../oo-deciding-object-or-data/SKILL.md)
  rule 3, for a transfer object converted once at the edge.
- [oo-placing-domain-logic](../oo-placing-domain-logic/SKILL.md)
  rule 5, for well-formed input at the edge and the allowed decision in
  the domain.
- [oo-separating-presentation-from-domain](../oo-separating-presentation-from-domain/SKILL.md)
  rule 2, for screen state and screen logic in a presentation object.
- [oo-patterns-the-language-provides](../oo-patterns-the-language-provides/SKILL.md)
  rules 6 and 7, for a container where a framework builds objects and
  for following the code's idiom.
- [oo-documenting-design-decisions](../oo-documenting-design-decisions/SKILL.md)
  rule 1, for a record of a choice that is costly to reverse.

## Further reading

- [Framework pressures](references/pressures.md)
- [When the framework is not object-oriented](references/not-object-oriented.md)
