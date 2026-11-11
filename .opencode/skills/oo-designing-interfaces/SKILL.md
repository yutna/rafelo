---
name: oo-designing-interfaces
description: Use when an interface has methods its callers never use, when it copies public members of one type, or when picking interface or abstract base.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Interfaces

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An interface is a promise a caller reads. When it grows to hold every
message the class can answer, each caller depends on messages it never
sends, and every change to the class reaches all of them. This skill
shapes each interface around one caller's role, splits an interface
whose callers use separate parts, and keeps a copy of one class out of
the interface. It also chooses between an interface and an abstract base
class, and decides when a generic type may stand in for one built on a
subtype or a parent type.

## When to use

- An interface has methods that some of its callers never send.
- Two callers of one interface use separate parts of it.
- An interface copies every public member of one class.
- A class is about to implement a role, and the caller's side of the
  contract is unclear.
- The choice is between an interface and an abstract base class.
- A generic type must be passed where a type built on a subtype or a
  parent type is expected.

## When not to use

- The type has one caller and one implementation, and no seam is needed
  yet: write no interface, and let
  [encapsulating what varies](../oo-encapsulating-what-varies/SKILL.md)
  decide whether the evidence justifies a seam.
- The question is whether an implementation keeps the interface's
  promise:
  [honouring substitutability](../oo-honouring-substitutability/SKILL.md)
  checks the contract.
- The type only carries data and has no behaviour to put behind a role:
  [deciding object or data](../oo-deciding-object-or-data/SKILL.md)
  makes that call.

## Core rules

1. Rule. **Shape an interface around the caller that uses it, not around
   the class that implements it.** Name it for the role the caller
   needs, such as `FreeSlots` or `DoseStock`, and give it only the
   messages that role sends. One class may play several roles by
   implementing several interfaces.

2. Rule. **Never make a caller depend on a message it never sends.**
   When the callers of one interface use separate parts of it, split it
   so that each caller's interface holds only what that caller sends. A
   change to a message then reaches only the callers that send it, and a
   stand-in for one caller answers only that caller's part.

3. Default. **Do not extract an interface that copies every public
   member of one class.** It doubles each change and hides nothing.

   The exception is a seam a caller needs replaced now, such as an
   outside system that a test stands in for; even then the interface
   holds only what that caller sends.

4. Judgement. **Choose an interface when the implementations share only
   a promise, and an abstract base class when they share state or a
   fixed order of steps that the base class owns.** What tips the
   balance is whether the shared code is the point: a base class binds
   every implementation to its fields and to which of its own methods
   it sends, so prefer the interface unless the code would otherwise be
   repeated. A base class that stays open writes down which methods an
   override may replace and which of its own methods send them; the
   written self-use is what makes the dependence safe.

5. Default. **Name the role a type plays and declare which types play
   it, even where a language matches types by their shape.** Two
   unrelated types whose messages happen to share names are
   interchangeable by accident, and a named role tells a reader which
   matches are meant.

   The exception is a small callback whose shape is its whole contract,
   such as a message with one parameter that one caller passes.

6. Rule. **Set a generic parameter's direction from how the type uses
   it.** A type that only hands values out may be read as one of a wider
   type: a `ReadOnlyList<Vaccination>` can be read where a
   `ReadOnlyList<VisitKind>` is expected. A type that only takes values
   in may stand in for one that takes a narrower type. A type that both
   takes and hands out stays exact: a `List<Vaccination>` cannot stand
   where a `List<VisitKind>` is added to, or a `Procedure` could be
   added to it. The notation has no syntax for direction; the language
   packs show it.

## Pattern

Before, `SlotStore` copies the four public messages of `ClinicSlots`.
`Reception` sends only `freeSlots` and `NightlyExport` only `export`,
yet both hold the whole interface. After, each caller holds only the
role it sends, and `ClinicSlots` keeps `save` and `remove` as its own
public messages.

Before:

```text
interface SlotStore
  + freeSlots(date: Date): ReadOnlyList<Slot>
  + save(slot: Slot): void
  + remove(slot: Slot): void
  + export(): String

class ClinicSlots implements SlotStore
  - slots: List<Slot>
  + new()
    slots := new List<Slot>()
  + freeSlots(date: Date): ReadOnlyList<Slot>
  + save(slot: Slot): void
  + remove(slot: Slot): void
  + export(): String

class Reception
  - slots: SlotStore
  + new(slots: SlotStore)
  + freeOn(date: Date): ReadOnlyList<Slot>
    return slots.freeSlots(date)

class NightlyExport
  - store: SlotStore
  + new(store: SlotStore)
  + run(): String
    return store.export()
```

`Slot` appears only as a type in both fences, with the shape
`notation.md` gives it. `ClinicSlots` shows its four methods as
signatures only. `new List<Slot>()` is taken to make an empty list.
`freeSlots` is taken to return a read-only view of the slots that have
no patient on the date, `save` to add the slot once, `remove` to take
it out once, and `export` to return the held slots as text. Both
callers hold a `SlotStore`, so a change to `save` reaches both, though
neither sends it.

After:

```text
interface FreeSlots
  + freeSlots(date: Date): ReadOnlyList<Slot>

interface SlotExport
  + export(): String

class ClinicSlots implements FreeSlots, SlotExport
  - slots: List<Slot>
  + new()
    slots := new List<Slot>()
  + freeSlots(date: Date): ReadOnlyList<Slot>
  + save(slot: Slot): void
  + remove(slot: Slot): void
  + export(): String

class Reception
  - slots: FreeSlots
  + new(slots: FreeSlots)
  + freeOn(date: Date): ReadOnlyList<Slot>
    return slots.freeSlots(date)

class NightlyExport
  - report: SlotExport
  + new(report: SlotExport)
  + run(): String
    return report.export()
```

`class ClinicSlots implements FreeSlots, SlotExport` is taken to mean
that `ClinicSlots` implements both interfaces. The notation has no
syntax for a list of implemented interfaces, which is why the one
sentence states it. `ClinicSlots` keeps `save` and `remove` as its own
public methods, and its four methods still appear as signatures only,
with the meanings above. `Reception` holds only a `FreeSlots` and
`NightlyExport` only a `SlotExport`, each set by its constructor, so a
change to `save` reaches neither caller and a stand-in for a caller
answers only that caller's role.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- An interface whose callers each use a different small part of it.
- An implementation that raises a not-supported error or leaves a body
  empty for a message it cannot serve.
- An interface named after the class it was copied from, such as
  `ClinicSlotsInterface`.
- A test stand-in that must answer messages the test never sends.
- An abstract base class with no state and no fixed steps, only
  abstract methods.

## Common mistakes

- Extracting an interface from every class by habit.
- Splitting an interface per message, so callers juggle several
  one-message interfaces that always travel together.
- Growing one interface for every new caller instead of giving the new
  caller its own role.
- Choosing an abstract base class to share two lines of code, which
  binds every implementation to its fields.
- Treating a list of a subtype as a list of its parent in a place that
  adds to it.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-what-varies](../oo-encapsulating-what-varies/SKILL.md)
  decides whether a seam has evidence.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  checks that each implementation keeps the promise the interface makes.
- [oo-choosing-composition-over-inheritance](../oo-choosing-composition-over-inheritance/SKILL.md)
  weighs a base class against a held collaborator.

## Further reading

- [Roles and headers](references/roles-and-headers.md)
- [Shapes and variance](references/shapes-and-variance.md)
