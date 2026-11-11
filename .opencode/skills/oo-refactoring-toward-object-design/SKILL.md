---
name: oo-refactoring-toward-object-design
description: Use when restructuring working code without changing what it does, when a refactoring grew too big to finish, or when moving toward a pattern.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Refactoring Toward Object Design

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Working code can take a better shape without changing what the clinic
sees. This skill separates the two kinds of change: one step alters
structure, the next alters behaviour, never both at once. It pairs every
move with a rule of this pack and a run of the tests, so each step can
be judged and undone on its own. It also says where to stop, at the rule
the code now keeps, at the pattern whose force has gone, or before code
that no change needs.

## When to use

- A method, class or module has become hard to read while it must keep
  working through the change.
- A refactoring branch has run for days and no longer merges cleanly.
- A change is about to land in code whose shape makes it touch many
  places.
- A pattern's force has appeared or gone, and the code around it must
  follow.
- A step needs a name before anyone takes it.

## When not to use

- The code has no tests and must change now: pinning what it does before
  any step is in
  [working with legacy code](../oo-working-with-legacy-code/SKILL.md).
- The change adds or alters behaviour, such as a new clinic rule: the
  skill that owns that rule shapes it, and any refactoring is a separate
  step before or after.
- The question is which antipattern to treat first: that is
  [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md).
- The question is whether a pattern pays its way at all: that is
  [choosing a pattern](../oo-choosing-a-pattern/SKILL.md).

## Core rules

1. Rule. **Change structure and behaviour in separate steps.** A
   refactoring step changes nothing a test or a caller can observe. A
   change in behaviour is a step of its own, made before or after the
   refactoring, never inside the same step.

2. Rule. **Refactor only under tests that pass before the first step
   and after every step, and keep what those tests check the same.** A
   step may rename or move the messages a test sends, never what the test
   expects. A test that must change what it expects for a refactoring was
   checking the inside, which
   [testing object-oriented code](../oo-testing-object-oriented-code/SKILL.md)
   rule 1 forbids; change that test first, in a step of its own.

3. Default. **Take the smallest named move that leaves the code
   working, and run the tests after each move.** Examples are renaming,
   extracting a method, moving a method, extracting a class, inlining a
   method or a class, and replacing a primitive with a value.

   The exception is a move the editor's own refactoring tool makes and
   checks, such as a rename across the whole code base: it is one step
   however many lines it touches.

4. Rule. **Aim each move at a rule of this pack, and stop when the code
   keeps it.** A method that uses another object's data more than its own
   moves to that object
   ([limiting what an object knows](../oo-limiting-what-an-object-knows/SKILL.md)
   rule 5). A primitive that carries a domain rule becomes a value
   ([modeling values and entities](../oo-modeling-values-and-entities/SKILL.md)
   rule 5). The same switch on a type in more than one place becomes one
   class per case
   ([replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
   rule 1). A chain of messages through other objects becomes one message
   to the nearest object
   ([limiting what an object knows](../oo-limiting-what-an-object-knows/SKILL.md)
   rule 2). A class changed for two kinds of request splits in two
   ([assigning responsibilities](../oo-assigning-responsibilities/SKILL.md)
   rules 7 and 8). A subclass that refuses its parent's messages stops
   extending the parent, or the parent's contract widens
   ([honouring substitutability](../oo-honouring-substitutability/SKILL.md)
   rule 7). A smell that
   [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md)
   names, such as a god class, is sorted there first.

5. Rule. **Move toward a pattern only while its force is present, in
   moves that each keep the tests passing, and stop as soon as the force
   is resolved.** [Choosing a pattern](../oo-choosing-a-pattern/SKILL.md)
   rule 2 asks for that evidence. Move away from a pattern the same way
   once its force has gone, as choosing a pattern, rule 6, asks.

6. Default. **Refactor the code a change is about to touch before making
   the change.** First reshape it until the change fits in one place,
   with the tests passing; then make the change as a step of its own.

   The exception is code no change needs, which
   [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md)
   rule 5 leaves alone.

7. Rule. **When a step breaks a test, undo the step and take a smaller
   one.** Never fix forward on top of a failing test, because each
   further step hides which move broke it.

## Pattern

Before, `TransportDesk` asks a `TransportRequest` for its data and
decides which fare applies. After, the request answers its own fare and
the desk delegates.

`Distance` and `Fare` are values taken as given. `FareTable` is taken to
answer each fare from the clinic's price list and to change nothing. Both
fences store nothing.

Before:

```text
interface FareTable
  + standardFare(distance: Distance): Fare
  + wheelchairFare(distance: Distance): Fare

class TransportRequest
  - distance: Distance
  - wheelchair: Boolean
  + new(distance: Distance, wheelchair: Boolean)
  + distance(): Distance
    return distance
  + needsWheelchair(): Boolean
    return wheelchair

class TransportDesk
  - fares: FareTable
  + new(fares: FareTable)
  + fareFor(request: TransportRequest): Fare
    if request.needsWheelchair() then
      return fares.wheelchairFare(request.distance())
    else
      return fares.standardFare(request.distance())
```

`TransportDesk.fareFor` uses the request's data more than its own
([limiting what an object knows](../oo-limiting-what-an-object-knows/SKILL.md)
rule 5).

After:

```text
interface FareTable
  + standardFare(distance: Distance): Fare
  + wheelchairFare(distance: Distance): Fare

class TransportRequest
  - distance: Distance
  - wheelchair: Boolean
  + new(distance: Distance, wheelchair: Boolean)
  + fare(fares: FareTable): Fare
    if wheelchair then
      return fares.wheelchairFare(distance)
    else
      return fares.standardFare(distance)

class TransportDesk
  - fares: FareTable
  + new(fares: FareTable)
  + fareFor(request: TransportRequest): Fare
    return request.fare(fares)
```

The moves between the fences, each followed by a run of the tests, are:
move the body of `fareFor` to a new method `TransportRequest.fare(fares)`
and let `fareFor` send it; then remove `distance()` and
`needsWheelchair()` once no caller sends them. Whether `TransportDesk`
keeps `fareFor` is a later step, since a class that only forwards is
limiting what an object knows, rule 3's question. Each version answers
one fare for each `fareFor` and sends one message to `fares` for it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A commit that renames, moves and changes behaviour at once.
- A refactoring branch whose tests were edited to pass.
- A long run of edits between two runs of the tests.
- A pattern introduced with one case behind it.
- A failing test left while further moves continue.
- A structure change with no test covering the code it moves.

## Common mistakes

- Rewriting a module in one step and calling it a refactoring.
- Fixing a bug found along the way inside a refactoring step.
- Changing what a test expects so that a move passes.
- Moving toward a pattern beyond the point where its force is resolved.
- Refactoring code that no planned change touches.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-testing-object-oriented-code](../oo-testing-object-oriented-code/SKILL.md)
  keeps tests on what a caller can see, so a refactoring leaves them
  unchanged.
- [oo-recognising-antipatterns](../oo-recognising-antipatterns/SKILL.md)
  names the smell behind a move and orders the fixes.
- [oo-choosing-a-pattern](../oo-choosing-a-pattern/SKILL.md) asks
  whether a pattern's force is present, and when it has gone.
- [oo-limiting-what-an-object-knows](../oo-limiting-what-an-object-knows/SKILL.md)
  moves a method to the object whose data it uses, and removes a class
  that only forwards.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)
  decides when a primitive becomes a value.
- [oo-replacing-conditionals-with-polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  gives each case of a repeated switch its own class.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  splits a class that changes for two kinds of request.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  decides when a subclass stops extending its parent.
- [oo-working-with-legacy-code](../oo-working-with-legacy-code/SKILL.md)
  pins what untested code does before the first refactoring step.

## Further reading

- [Smells and moves](references/smells-and-moves.md)
- [Toward and away from a pattern](references/toward-and-away-from-a-pattern.md)
