---
name: oo-naming-classes-and-methods
description: Use when choosing what to call a class or method, when names end in Manager, Helper or Util, or when a name no longer says what the code does.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Naming Classes and Methods

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A name is the shortest description of a piece of code, and every reader
pays for it again at each call. This skill chooses names that say what an
object is, what a command does and what a query answers. It keeps one
word for one concept and moves a name in the same change that moves its
meaning. It does not choose the clinic's words for a concept; it makes
the chosen words honest and consistent.

## When to use

- A new class or method needs a name.
- A name ends in Manager, Helper, Util, Processor or Data, or a method
  is called `process` or `handle`.
- A reader cannot tell what a method returns or what a class holds.
- Two words describe the same concept in nearby code.
- A name still describes the old behaviour after a change.

## When not to use

- The class does several unrelated jobs and no honest name fits it:
  split it first, as
  [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md)
  describes.
- The question is which words the clinic's staff use for a concept, or
  two teams use one word for different things: that is a question of the
  domain's language, not of naming grammar.
- The name is fixed by a framework or a protocol, such as a lifecycle
  method the framework calls or a field a message format requires.
- The spelling or prefix is fixed by the language or its tools, such as
  the form an accessor must take. The language pack carries that
  convention.

## Core rules

1. Rule. **Name a class for what each instance is, or for the one job it
   does, as a noun phrase.** `Slot`, `WaitingList` and `RoomPlanner` say
   what an instance is or the job it owns. When the only name that fits
   ends in Manager, Helper, Util, Processor or Data, the class has no
   single job yet: find its job first, as
   [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md)
   describes, and the name follows.

2. Rule. **Name a command for the effect it has, as a verb phrase, and a
   query for the answer it gives, as a noun phrase or a yes-or-no
   question.** `reserve`, `cancel` and `register` name effects;
   `startsAt`, `fee` and `isFree` name answers. A query's name on a
   method that changes state misleads every caller; whether such a
   method is split follows rule 4 of
   [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md),
   including its exception for returning what was just created. An
   operation on an immutable value that returns the changed copy may
   take the verb of the change it models, such as `plus`, because it
   changes nothing.

3. Default. **Name for what the code means to its callers, not for how
   it works inside.** `waiting()` says what a caller learns, where
   `patientList()` says how the answer is stored. `freeSlots(date)` says
   what a caller may do with the answer, where `slotsWithNoPatient(date)`
   says how the code decides.

   The exception is a class whose job is the mechanism itself, such as
   an adapter for an outside system: the outside system's name is its
   meaning.

4. Rule. **Use one word for one concept throughout the code, and
   different words for different concepts.** If one class says `cancel`,
   no sibling says `revoke` for the same act, and `slot` never also
   means a room. A reader who learns a word once can trust it everywhere.
   The rule holds inside one model; separately owned contexts may each
   give one word a meaning of their own, as
   [bounding contexts](../oo-bounding-contexts/SKILL.md) describes.

5. Judgement. **Match a name's length to how far from its declaration it
   is read.** A two-line local may be short, while a public class or
   method read across the code needs a name that stands alone. What tips
   the balance is whether a reader at the farthest use can tell what the
   name holds without opening its declaration.

6. Default. **Rename in the same change that changes a name's
   meaning.** A name that no longer says what the code does costs every
   later reader, and a comment explaining the gap is the sign. The change
   that widens the behaviour carries the rename, so no revision shows the
   old name on the new behaviour.

   The exception is a name other systems depend on, such as a published
   interface or a stored code: add the new name beside the old one and
   retire the old one on a schedule.

## Pattern

Before, every name in `PatientHelper` describes a mechanism rather than
a register of patients. After, the same class is `PatientRegister`, with
method and parameter names that say what each one means. Only names
change: the field still holds a `List<Patient>`, the constructor still
creates an empty list, and each method sends the same message and
returns the same kind of result.

Before:

```text
class PatientHelper
  - items: List<Patient>
  + new()
    items := new List<Patient>()
  + add(x: Patient): void
    items.add(x)
    return
  + lookup(x: Patient): Boolean
    return items.contains(x)
```

After:

```text
class PatientRegister
  - patients: List<Patient>
  + new()
    patients := new List<Patient>()
  + register(patient: Patient): void
    patients.add(patient)
    return
  + isRegistered(patient: Patient): Boolean
    return patients.contains(patient)
```

`add` and `register` each send `add` to the field once. `lookup` and
`isRegistered` each send `contains` to the field once and change
nothing. The constructor sets the field before any read, and the list
stays private, so no caller receives it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A class name ending in Manager, Helper, Util, Processor, Handler or
  Data.
- A method called `process`, `handle`, `execute` or `perform` on a class
  with more than one job.
- A method whose name reads as a query, such as `get...` or `is...`, but
  which changes state.
- A boolean parameter that switches a method between two behaviours.
- Two words for one concept in the same code, or one word for two
  concepts.
- A comment that says what a name should have said.

## Common mistakes

- Renaming a Manager to a Service and keeping all its jobs.
- Putting the type or the storage in a name, such as `patientList` or
  `slotMap`.
- Shortening a public name to save typing.
- Naming a class for the pattern it uses when its callers only need its
  job.
- Keeping a name after its meaning changed and explaining the gap in a
  comment.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  finds the class and the job before its name.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps a command and a query apart, and keeps a collection private.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) lets
  separately owned contexts give one word a meaning of their own.

## Further reading

- [Names that mislead](references/names-that-mislead.md)
- [Vague words](references/vague-words.md)
