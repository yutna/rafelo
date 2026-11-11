---
name: oo-encapsulating-state-and-behaviour
description: Use when callers check an object's state to decide for it, when any caller can set it into a broken state, or when a getter leaks a collection.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Encapsulating State and Behaviour

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An object that holds state should also hold the rules about that state.
Otherwise every caller has to remember the rules, and one caller that
forgets puts the object into a shape the rest of the code cannot use.
This skill keeps the state private, changes it through messages named
for clinic actions, and hands out answers instead of raw collections.

## When to use

- A caller reads a field or a getter and then decides what to do next.
- A public setter lets any caller put the object into a broken state.
- A getter returns the internal list or map, so a caller can change it.
- A method changes state and returns a computed answer at the same time.
- A constructor or method stores a list or a date the caller still holds.
- A review asks where an invariant should live.

## When not to use

- The type only carries data across a boundary, such as a DTO. Keep it
  plain and convert it at the edge.
- A framework needs setters or a no-argument constructor for its
  mapping, and the rule is enforced elsewhere. Follow the framework, and
  say in the code where the rule lives.
- The object has no state that changes. A value or a plain record is
  enough, and getters break no rule.
- The question is whether the type should be an object at all. Decide
  that first, then return here for the state it holds.

## Core rules

1. Rule. **An invariant belongs to the object that holds the state.**
   Every method that changes that state keeps the invariant true,
   including the constructor and any method that replaces a collection.
   Callers get no way to assemble a state the rules forbid.

2. Default. **Add no setter; change state through a method named for the
   domain action.** `reschedule`, `cancel` and `record` read the current
   state, check the rule, and change only what the action allows.

   The exception is a framework that maps fields through setters or a
   no-argument constructor. Let it map at the edge, enforce the rule in
   the object's action method, and say in the code where the rule lives.

3. Rule. **Tell the object what to do instead of asking for its state
   and deciding for it.** Replace the getter-check-set sequence with one
   message that names the action. The object owns the decision, and every
   caller gets the same answer.

4. Default. **A command changes state and returns nothing; a query
   returns an answer and changes nothing.** Keep the two apart, so a
   caller can ask without causing a write and repeat a question without
   a second effect.

   The exception is the identifier of something just created, such as a
   new booking's identifier. Returning it is deliberate, and the method
   still does one job: create the thing.

5. Rule. **Never hand out the internal collection.** Offer methods that
   name what callers may do with it, or return a read-only view. A caller
   that needs to read the list uses the view; a caller that needs to
   change it sends the object a message.

6. Rule. **Copy a mutable input or output at the boundary.** Copy a list
   passed in before storing it, and copy a mutable list or a date handed
   out before the caller gets it, so later changes on either side cannot
   reach the object's state. A read-only view cannot be changed by the
   caller, though it shows the object's later changes, so a view is the
   alternative when callers only read. An entity is not a mutable
   value: a `Slot` is shared by identity, so a method that records one
   keeps the instance it was given.

## Pattern

Before, `Clinician.slots()` returns the internal list. `Scheduler`
appends to that list directly, so two slots that overlap can both land
on the same clinician.

Before:

```text
class Clinician
  - slots: List<Slot>
  + new(slots: List<Slot>)
  + slots(): List<Slot>
    return slots

class Scheduler
  - clinician: Clinician
  + new(clinician: Clinician)
  + schedule(slot: Slot): void
    clinician.slots().add(slot)
    return
```

`clinician.slots().add(slot)` is taken to mean that the returned list
appends the slot in place, because `slots()` returned the list the
clinician holds. The scheduler changes the clinician's state, and the
clinician never checks the overlap rule.

After, `addSlot` checks the overlap and raises `SlotsOverlap`.
`slots()` returns a read-only view, so no caller can append to the list.
`Scheduler` tells the clinician what to do and does not read the state.

After:

```text
class Clinician
  - slots: List<Slot>
  + new()
    slots := new List<Slot>()
  + addSlot(slot: Slot): void
    raises SlotsOverlap
    if slots.anyOverlaps(slot) then
      raise SlotsOverlap
    else
      slots.add(slot)
    return
  + slots(): ReadOnlyList<Slot>
    return slots.readOnlyView()

class Scheduler
  - clinician: Clinician
  + new(clinician: Clinician)
  + schedule(slot: Slot): void
    clinician.addSlot(slot)
    return
```

`new List<Slot>()` is taken to mean an empty list the clinician owns.
`slots.anyOverlaps(slot)` is taken to mean true when some slot the
clinician already holds overlaps the new one. `slots.add(slot)` appends
to the clinician's own list once. `slots.readOnlyView()` returns a
`ReadOnlyList<Slot>` that readers cannot change. `addSlot` is a command
and returns nothing; `slots()` is a query and changes nothing. Every
field is private, and the constructor sets `slots` before `addSlot` or
`slots` reads it. The clinician keeps the `Slot` it was given, because a
slot is an entity shared by identity and the copy rule does not apply to
it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A getter whose result another class tests before it acts.
- Public setters on a domain object.
- A method that both changes state and returns a computed answer.
- A getter that returns the internal list or map.
- A constructor or method that stores a mutable object the caller still
  holds.
- A caller that reads two getters and then picks the next call itself.

## Common mistakes

- Making every field private and then adding a getter and a setter for
  each one.
- Putting the rule in a setter instead of in the method named for the
  action.
- Copying on every read where nothing could change the data.
- Forcing every command to return nothing when returning the new
  identifier is clearer.
- Applying these rules to a DTO that only carries data across a
  boundary.
- Returning a read-only view and assuming callers no longer need an
  action method.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  chooses the class that owns a rule and its data.
- [oo-deciding-object-or-data](../oo-deciding-object-or-data/SKILL.md)
  tells a domain object from data at a boundary.

## Further reading

- [Guarding collections](references/guarding-collections.md)
