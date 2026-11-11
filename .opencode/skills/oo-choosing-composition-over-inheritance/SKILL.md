---
name: oo-choosing-composition-over-inheritance
description: Use when a subclass only reuses code, when a base class change breaks its subclasses, or when choosing between extending a class and wrapping it.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Choosing Composition over Inheritance

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A class that wants another class's work has two ways to get it. It can
extend the other class and inherit its messages, or it can hold an
instance and send messages to it. Extending is a statement about kinds:
a class that extends a collection is claiming to be a collection, and
every caller may treat it as one. Holding is a statement about use: the
holder offers only the messages it means to offer. This skill chooses
between the two, keeps a subclass from depending on how its parent is
written, and flattens hierarchies that cost more to read than they save.

## When to use

- A subclass adds a rule or a convenience and wants the parent's code,
  not its type.
- A change to a base class breaks subclasses that nobody edited.
- A design choice is between extending a class and holding an instance
  of it.
- A class inherits a message it cannot honour, or overrides one to do
  nothing.
- One behaviour takes three or more classes to follow.
- A mixin, module or trait is about to share state between classes that
  are not related.

## When not to use

- The class must extend a base type its framework requires, such as a
  base controller or a test case class. Follow the framework and keep
  domain rules out of that subclass.
- The subclass already keeps every promise of its parent, and the
  question is how to state or check those promises. That is a question
  of substitutability, not of reuse.
- The hierarchy exists to replace a repeated conditional on a type code.
  The hierarchy is the answer there, so this skill would remove the
  wrong thing.

## Core rules

1. Default. **Reuse behaviour by holding an object that has it and
   forwarding to it, not by extending its class.** A held object is asked
   only through its public messages, and the class that holds it decides
   which of those messages it offers. Extending a class says more than
   reuse: it says the subclass can stand wherever the parent is expected.

   The exception is a subclass that is a kind of its parent everywhere
   the parent is used, and whose parent was built to be extended. Then
   inheritance states that relationship directly, and a caller may use
   the subclass in place of the parent.

2. Rule. **Do not extend a class only to reuse its code.** A subclass
   offers every public message of its parent. If one of those messages
   would let a caller break the subclass's rules, or the subclass has to
   switch one off, hold the other class instead.

3. Rule. **Never let a subclass depend on a send its parent keeps
   internal.** An override that works because the parent sends it from
   another method breaks when the parent's author changes that internal
   send. A class that holds the other object sees only its public
   messages, and the internal sends cannot reach it. A parent built for
   extension writes those sends into its contract, as honouring
   substitutability's rule 5 asks, and then they are a promise a
   subclass may rely on, not an internal send.

4. Judgement. **Flatten a hierarchy when understanding one behaviour
   means reading up and down several levels.** Each level adds a place
   where a message sent to the object itself can land. What tips the
   balance is whether one class and its parent explain the behaviour.
   Weigh what the reading costs against what the hierarchy explains; a
   real kind-of relationship, as rule 1's exception allows, weighs on the
   side of keeping it.

5. Default. **Share behaviour across unrelated classes with an object
   each one holds, not with a mixin, module or trait that reads or writes
   the host's fields.** A held object has its own fields and offers
   messages. Code mixed into a host shares the host's fields and can
   break rules the host keeps.

   The exception is a mixin that uses only messages its host already
   offers in public, such as an ordering built from a comparison the host
   defines. It adds behaviour without touching the host's fields, so the
   host cannot break it by changing a field.

6. Rule. **Offer only the messages the reusing class means to offer.**
   Write one forwarding method for each message the reusing class
   promises, and never forward the held object's whole interface by
   habit. A narrow interface is the point of holding the object.

## Pattern

Before, `WaitingList` extends a collection and adds one rule. After, it
holds a collection and offers only the messages its callers need.

Before:

```text
class WaitingList extends List<PatientId>
  + join(patient: PatientId): void
    raises AlreadyWaiting
    if contains(patient) then
      raise AlreadyWaiting
    else
      add(patient)
    return
```

`contains(patient)` and `add(patient)` have no receiver, so each goes to
the `WaitingList` itself and lands on the collection it inherited. Every
message a `List` answers is now a public message of `WaitingList`, so a
caller can send `add` directly and put a patient on the list twice.
`join` adds no state, and the inherited `add` still lets any caller
append.

After:

```text
class WaitingList
  - patients: List<PatientId>
  + new()
    patients := new List<PatientId>()
  + join(patient: PatientId): void
    raises AlreadyWaiting
    if patients.contains(patient) then
      raise AlreadyWaiting
    else
      patients.add(patient)
    return
  + waiting(): ReadOnlyList<PatientId>
    return patients.readOnlyView()
```

`new List<PatientId>()` is taken to mean an empty list that the waiting
list owns. The constructor sets `patients` before `join` or `waiting`
reads it. `join` checks the held list, raises `AlreadyWaiting` without
appending when the patient is already there, and appends once otherwise.
`waiting()` returns a read-only view, so a caller reads the list but
cannot append to it. Only `new`, `join` and `waiting` are public: no
`add`, no `contains`, and no way to replace the list. The constructor is
plain because the list has one way to be made; a factory would add a step
without adding a rule.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A subclass that overrides a method to do nothing or to raise an error.
- A subclass that uses only a few of its parent's methods.
- An override that works only because the parent sends it from another
  method.
- A hierarchy where reading one behaviour means opening three or more
  classes.
- A mixin, module or trait that reads or writes its host's fields.
- A base class change that forces edits in subclasses nobody asked
  about.
- A parent setter whose only callers are subclasses filling a field the
  parent keeps private.

## Common mistakes

- Replacing inheritance with a held object but forwarding every message,
  which keeps the old interface and its problems.
- Treating any shared code as a reason to extend.
- Extending a class from a library or another team that was not built to
  be extended.
- Switching off an inherited method by raising an error in the override.
- Using a mixin to share state between unrelated classes.
- Keeping a hierarchy because the classes look alike, when only their
  code is shared.
- Expecting an override to keep running after the switch to holding,
  when the held object's internal sends no longer reach the holder.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps the held object's state behind its own messages and returns a
  read-only view from a query.
- [oo-encapsulating-what-varies](../oo-encapsulating-what-varies/SKILL.md)
  isolates the part that changes behind an interface, which is how a held
  collaborator is chosen.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  states the contract a subclass must keep, which is what rule 3 relies
  on when the parent is written for extension.

## Further reading

- [Fragile hierarchies](references/fragile-hierarchies.md)
