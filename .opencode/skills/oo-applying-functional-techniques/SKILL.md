---
name: oo-applying-functional-techniques
description: Use when calculating also writes or sends so tests need mocks, when a helper changes what it was handed, or when borrowing functional style.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Applying Functional Techniques

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A calculation that reads a clock, a store or a sender cannot be checked
from its arguments alone, and a helper that changes what its caller
handed it leaves the caller with data it never asked to change. This
skill keeps a decision free of effects, leaves a caller's data
untouched, and places each borrowed technique inside the module's own
objects. The clinic keeps its classes and gains tests that need no
stand-in for a store, a clock or a sender.

## When to use

- A method named for a calculation also reads the store, sends a notice
  or saves its own answer, so its test needs stand-ins.
- A helper adds to, removes from or otherwise changes a list or another
  mutable value that its caller still holds.
- A use case mixes its decision with the reading and the writing, and
  only an integration test can reach the decision.
- A module built of classes has started collecting free functions passed
  from step to step.
- A team wants the benefit of a pure calculation, a value or a function
  value without turning its object module into a second design.

## When not to use

- The question is whether a strategy, a command or a varying step could
  be a function value: that is patterns the language provides, rules 1
  to 3.
- The question is whether new kinds or new operations arrive more often:
  that is replacing conditionals with polymorphism, rule 7.
- The module is built of functions and plain values, with no classes:
  its own idiom applies, as patterns the language provides, rule 7,
  says.
- The data is shared between threads or tasks: that is managing shared
  state, rule 1.

## Core rules

1. Default. **Write a calculation as a pure method: it answers from its
   parameters and the object's own fields alone, changes nothing, and
   reads no clock, store or other system, so the same arguments always
   give the same answer.** A pure method can run twice, in any order and
   in any test, with nothing to set up: its answer never depends on what
   ran before it. A calculation that reaches a clock, a store or a
   sender has to be tested around that collaborator, and its answer
   changes with the world rather than with its arguments.

   The exception is a count or a total that applies no business rule,
   such as how many visits a report counts in a year: a read query in
   the store works it out, as layering the system, rule 6, lets such a
   read skip the domain.

2. Rule. **Never change a list or other mutable data that a caller
   handed you and still holds: copy it before changing it, or answer a
   new value.** An entity passed in changes only through a command it
   offers, named for the change, as the notation's `Appointment.book`
   sends `slot.reserve(patient)`. A helper that quietly changes what it
   was handed leaves its caller holding data it never asked to change.
   This rule protects a caller's argument during a call; encapsulating
   state and behaviour, rule 6, copies at an object's boundary to
   protect the state it keeps, and modeling values and entities, rule 2,
   makes a value immutable, so a value needs neither.

3. Default. **Arrange a use case as a pure core inside a shell: the
   shell reads everything the decision needs, hands it to domain objects
   and pure methods that reach no port, and then carries out what their
   answer names, such as storing an aggregate or sending a notice.**
   Designing for testability, rule 6, separates one class's decision
   from its effect; this rule does the same for a whole use case, so a
   test reaches every decision in it with values alone.

   The exception is a decision that needs the outcome of an effect part
   way through, such as a payment that may be refused before a booking
   is confirmed: run it as two decisions, one before the effect and one
   after it.

4. Rule. **Borrow a technique inside the module's own idiom, never as a
   second architecture beside its objects: a pure method stays a method
   of the object that owns the data, a value stays a value type, and a
   function value enters only where patterns the language provides,
   rules 1 to 3, place one.** Keep the module's classes and give each
   borrowed technique the shape its neighbours already have. A strategy
   class with one operation, no state and no name the staff use is not
   one of those classes: patterns the language provides, rule 1, passes
   it as a function value. Do not rebuild the module as free functions
   passed from step to step, as result values chained in place of the
   refusals that designing failure behaviour, rule 1, raises, or as
   pipelines composed from small functions; patterns the language
   provides, rule 7, keeps each module in the idiom it already uses.

## Pattern

`Weight` is a value, so it is immutable and compares by its contents.
`Weight.averageOf(list)` is taken to be a static method
that answers the mean of the weights in a list and changes nothing, a
calculation that uses only its argument, which designing for
testability, rule 5, allows a static method.

Before:

```text
class WeightTrend
  + averageWith(readings: List<Weight>, latest: Weight): Weight
    readings.add(latest)
    return Weight.averageOf(readings)
```

In the Before, `averageWith` answers the average and adds `latest` to
the caller's list. A caller that asks twice counts the latest reading
twice, and a caller that shows its list afterwards shows a reading it
never added (rule 2). The answer also depends on how often the method
has been called (rule 1).

After:

```text
class WeightTrend
  + averageWith(readings: List<Weight>, latest: Weight): Weight
    all := readings.copy()
    all.add(latest)
    return Weight.averageOf(all)
```

In the After, `averageWith` copies the list with `copy()`, adds to the
copy it owns, and answers the same average. The caller's list stays as
it was, and the same arguments give the same answer every time (rules 1
and 2). The copy protects the caller's argument during the call, while
encapsulating state and behaviour, rule 6, copies at an object's
boundary to protect the state the object keeps. `WeightTrend` keeps no
state, so it declares no field and no constructor. The fences store
nothing. Each version sends `add` once per call, and the After sets
`all` before reading it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A method named for a calculation that also writes to a store or sends
  a message.
- A helper that adds to, removes from or changes a list it was handed.
- A calculation whose answer changes when it is called twice with the
  same arguments.
- A use case whose decision needs stand-ins for the store and the sender
  to be tested.
- Free functions passed from step to step in a module built of classes.
- Result values passed along where the module raises refusals elsewhere.

## Common mistakes

- Answering a new copy of an entity the clinic tracks by identity,
  instead of sending it a command.
- Copying every argument on every call, where nothing changes it.
- Moving a read into the core because the decision needs one more fact.
- Rewriting a module into functions because one technique helped.
- Replacing a strategy the staff name with a function value.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [patterns the language provides](../oo-patterns-the-language-provides/SKILL.md)
  owns function values and the choice between a pattern and a function.
- [modeling values and entities](../oo-modeling-values-and-entities/SKILL.md)
  makes a value immutable.
- [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  copies at an object's boundary.
- [designing for testability](../oo-designing-for-testability/SKILL.md)
  splits one class's decision from its effect.
- [replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  chooses between subtypes and a closed set of cases.
- [placing domain logic](../oo-placing-domain-logic/SKILL.md) keeps the
  application service to loading, storing and the transaction.

## Further reading

- [A pure core in a shell](references/core-and-shell.md)
- [Where each borrowing lives](references/where-each-borrowing-lives.md)
