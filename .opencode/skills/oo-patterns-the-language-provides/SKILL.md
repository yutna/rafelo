---
name: oo-patterns-the-language-provides
description: Use when strategy or command classes could be functions, when writing an iterator or visitor by hand, or when the language builds in the pattern.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Patterns the Language Provides

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A pattern that costs an interface and a class per case can be replaced
by a feature the language already offers, when the force behind the
pattern is small. A function value is a piece of behaviour a caller may
pass around and call; it answers one message, `call(args)`, which runs
it and answers its result. A closed set lists every case in one place,
and exhaustive matching is a match over that set that handles each
case. The language's own iteration walks a collection through a
read-only view. The composition root builds the object graph, and a
container builds objects from its own configuration.

This skill keeps a pattern's classes where they carry state, several
operations or a name the staff use, and lets the language's feature
replace them where it does the same job.

## When to use

- A strategy, command or template step is a class with one method and
  no state, and a function value would do the same job.
- A caller walks a collection through a hand-written iterator class
  with its own next and has-next messages.
- A visitor adds operations to a closed set of cases, and the language
  checks that a match handles every case.
- A factory exists only to choose which implementation to wire, and the
  composition root can make the same choice.
- A design review asks whether the language now provides a pattern the
  module writes by hand.

## When not to use

- The language has no function values, no exhaustive matching or no
  built-in iteration for the case at hand: the class-based pattern
  stays.
- The question is which pattern a problem calls for at all: that is
  choosing a pattern, which
  [oo-choosing-a-pattern](../oo-choosing-a-pattern/SKILL.md) decides.
- The strategy or command carries state, several operations or a name
  the staff use: it keeps its class, as the core rules say.
- The question is the syntax of a function value or a match in one
  programming language: that is outside this skill.

## Core rules

1. Default. **Pass a function value where a strategy has one operation,
   holds no state and has no name the staff use: the function value is
   the strategy.** There is no interface to implement and no class per
   case, and the call sits where the choice is made. The exception is a
   strategy with several operations, state of its own, or a name in the
   clinic's language, such as the late-cancellation rule the staff discuss:
   it keeps its interface and classes, as replacing conditionals with
   polymorphism, rule 5, chooses a strategy.

2. Default. **Pass a function value for an action that is only ever run
   where it is made.** The call sits on the line that needs the action,
   so no class and no interface stand between the reader and the step.
   The exception is an action that must be queued, stored, logged,
   undone or retried: it stays a command object that carries its data.

3. Default. **Pass the varying step of a fixed algorithm to the class
   that runs the algorithm, as a function value, rather than extending
   a base class that leaves one step open.** The algorithm stays in one
   method, and the step arrives through the constructor. The exception
   is a group of steps that vary together or share the algorithm's
   state: hold them as one object behind a small interface, as choosing
   composition over inheritance, rule 1, does.

4. Rule. **Use the language's own iteration instead of an iterator
   class: hand callers a read-only view or a sequence the language can
   walk, never a hand-written object with its own next and has-next
   messages, and keep the collection itself private.** An iterator
   class repeats what the language already does, and its own cursor is a
   second place to keep correct. A read-only view lets a caller read
   the collection without changing it, as encapsulating state and
   behaviour, rule 5, asks.

5. Judgement. **Replace a visitor with a closed set of cases and
   exhaustive matching where the language checks that every match
   handles every case.** A visitor is an object that adds an operation
   to every case by being sent each case in turn. With a closed set, a
   new operation is one match and no change to the cases, while adding
   a case makes the compiler list every match to update. What tips the
   balance is whether new operations or new cases arrive more often, as
   replacing conditionals with polymorphism, rule 7, weighs it, and
   whether the language checks exhaustiveness.

6. Rule. **Let the composition root, written by hand, do a factory's
   wiring work, and a container only where a framework builds its own
   objects, as inverting dependencies, rule 4 and its exception,
   allow.** A container is a tool that builds and wires objects from
   its own configuration, and no container reaches domain code, as rule
   5 there says. Keep a factory only where it decides how a domain
   object is born: a named factory that enforces a valid birth stays, as
   constructing valid objects, rule 4, asks.

7. Rule. **Follow the idiom the module already uses: where the module
   works with function values, a function value is the pattern; where
   it is built of classes the team reads, a class the team recognises
   can stay.** A feature that removes a pattern in one module is no
   reason to rewrite another. Changing the idiom costs more than the
   feature saves, and the reader pays it on every later change. A class
   the team recognises is one with a name the staff use, the exception
   rule 1 gives; a strategy with one operation, no state and no such
   name is passed as a function value in a module built of classes too.

## Pattern

Before, `ReminderPlanner` holds a `ReminderTiming` collaborator, an
interface with one operation, and `DayBefore` and `TwoHoursBefore` each
implement it without a field. After, the timing is a function value, and
`ReminderSetup` builds the planner where the object graph is wired.

Before:

```text
interface ReminderTiming
  + dueAt(appointment: Appointment): DateTime

class DayBefore implements ReminderTiming
  + dueAt(appointment: Appointment): DateTime
    return appointment.startsAt().minusDays(1)

class TwoHoursBefore implements ReminderTiming
  + dueAt(appointment: Appointment): DateTime
    return appointment.startsAt().minusHours(2)

class ReminderPlanner
  - timing: ReminderTiming
  + new(timing: ReminderTiming)
  + dueAt(appointment: Appointment): DateTime
    return timing.dueAt(appointment)
```

After:

```text
class ReminderPlanner
  - timing: (Appointment) -> DateTime
  + new(timing: (Appointment) -> DateTime)
  + dueAt(appointment: Appointment): DateTime
    return timing.call(appointment)

class ReminderSetup
  + dayBefore(): ReminderPlanner
    return new ReminderPlanner((appointment: Appointment) ->
      appointment.startsAt().minusDays(1))
```

`Appointment` gains no field here. `startsAt()` is the query the
crossing system boundaries skill adds to `Appointment`. `minusDays(1)`
and `minusHours(2)` are taken to answer the time that many days or hours
earlier, and `1` and `2` are taken to be the number of days and hours
those calls ask for. `ReminderSetup` stands for the composition root.
`ReminderTiming`, `DayBefore` and `TwoHoursBefore` disappear because
each held one operation, no state and no name the staff use. Both
fences store nothing, and each version answers one due time per call:
the Before sends one `dueAt` to its timing, and the After calls its
function value once inside `ReminderPlanner.dueAt`. Every method
answers a value and raises nothing. A second method,
`twoHoursBefore()`, passes
`(appointment: Appointment) -> appointment.startsAt().minusHours(2)`
the same way and is left out of the fence.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- An interface with one method whose implementations hold no fields.
- A hand-written iterator class over a collection the language can
  walk.
- A visitor in a language that checks exhaustive matching over a closed
  set.
- A factory whose only job is to pick which implementation to wire.
- A base class that exists to leave one step of an algorithm open.
- A module that mixes function values and one-method classes for the
  same kind of job.

## Common mistakes

- Turning a strategy the staff name into an anonymous function.
- Replacing a command that must be undone or retried with a bare
  function.
- Rewriting a class-based module in function values because the
  language allows it.
- Matching on a set of cases the language does not close, so a new case
  passes unnoticed.
- Moving a factory that enforces a valid birth into a container.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-choosing-a-pattern](../oo-choosing-a-pattern/SKILL.md) decides
  whether a pattern is needed at all.
- [oo-replacing-conditionals-with-polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  weighs subtypes against a closed set with exhaustive matching.
- [oo-choosing-composition-over-inheritance](../oo-choosing-composition-over-inheritance/SKILL.md)
  holds an object instead of extending a base class.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  builds the object graph at the composition root.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  gives a named factory its job and keeps it valid.

## Further reading

- [Functions for small patterns](references/functions-for-small-patterns.md)
- [Matching and iteration](references/matching-and-iteration.md)
