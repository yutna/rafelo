---
name: oo-designing-for-testability
description: Use when tests depend on today's date, random values or generated ids, when a constructor does real work, or code is made public only for tests.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing for Testability

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A test that is awkward to write is telling you something about the
design. When a test must build a working database, start a thread or
fix the machine's clock before it can check one rule, the object under
test has taken on work that belongs at its edge. This skill changes the
design so a test can choose every value it cannot repeat, reach every
collaborator through a port, and check only what a caller can see. A
test written this way repeats on every machine and does not care which
day it runs.

## When to use

- A test gives a different result on a different day, or after a
  restart, because something inside reads the time, draws a random
  value, generates an identifier or reads a setting.
- A test must build, start or reset many things to check one rule.
- A constructor reads a file, opens a connection or starts a thread.
- Code reaches a collaborator through a static call, a global or a
  class's single instance.
- One method both decides something and talks to a slow or effectful
  collaborator.
- A field, getter, flag or method exists only so a test can reach
  inside.
- You are choosing whether a collaborator needs a port, or whether a
  value can be passed as it is.

## When not to use

- The question is how to write or name a test, or which kind of
  stand-in to pass: that is
  [testing object-oriented code](../oo-testing-object-oriented-code/SKILL.md).
- The code has no tests and must change now, before its design can
  improve: getting a test around today's code is in
  [working with legacy code](../oo-working-with-legacy-code/SKILL.md).
- A screen, a scheduled job or a message listener cannot run without
  its framework: [layering the system](../oo-layering-the-system/SKILL.md)
  rule 4 keeps that edge humble.
- The dependency is a value or a library with no effects, such as date
  arithmetic, which a test can use as it is.

## Core rules

1. Rule. **Treat a test that is hard to write as a finding about the
   design: name what the test must build, start or reset before it can
   check one rule, and change the design that makes that work necessary,
   not the test.** The index's red flag, a test that needs many mocks to
   check one decision, is the usual sign.

2. Rule. **Receive every source of a value a test cannot repeat through
   a port passed into the constructor, and never ask the machine for it
   inside the object: the current time, a random draw, a newly generated
   identifier, a setting read from the environment.** These are outside
   systems like any other, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rules
   1 and 2 ask. A test then passes a stand-in, an object it puts in a
   real collaborator's place, that answers the value it chose.

3. Default. **Pass the value, not its source, to a domain object that
   needs only the value: an aggregate's method takes the time as a
   parameter, as
   [modeling lifecycles](../oo-modeling-lifecycles/SKILL.md) rule 5
   gives `recordNoShow(now)`, and the use-case object asks the port once
   and passes the answer on.** The exception is an object that must ask
   again while it handles one message, such as a long run that checks
   the time between items: it holds the port.

4. Rule. **Let a constructor set the object's fields, check its
   arguments and build the parts the object owns, and nothing more: it
   reads no file, opens no connection, starts no thread, sends nothing
   to an outside system and builds no collaborator with `new`.** What a
   constructor may build and what it must receive is decided by
   [constructing valid objects](../oo-constructing-valid-objects/SKILL.md)
   rule 6 and
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rule
   2; this rule keeps work out of the constructor, because that work
   runs in every test that builds the object.

5. Rule. **Reach no collaborator that has effects or answers differently
   from one call to the next through a static method, a global or a
   class's single instance: one object the class keeps for every caller.
   Keep static methods for named factories and for calculations that
   use only their arguments.** A static call cannot be replaced in a
   test, and a single instance carries one test's state into the next.
   Pass each collaborator in and build the single instance at the
   composition root, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rules
   2 and 3 ask.

6. Default. **Split the decision from the effect: put the logic that
   would otherwise need a slow or uncontrollable collaborator in an
   object that takes plain values and answers plain values, and keep the
   code that touches the collaborator so small that it needs no test of
   its own.** A humble object keeps only the code that needs the hard
   edge and sends the rest inward; this is the humble object that
   [layering the system](../oo-layering-the-system/SKILL.md) rule 4 asks
   of each edge, used inside any class. The exception is code with
   nothing to decide, such as a method that passes a value to its port.

7. Judgement. **Add a seam for a test only where the collaborator is
   slow, has effects or gives answers the test cannot choose, and use a
   value, or a domain object that is fast and answers the same every
   time, as it is.** A seam is an interface where one implementation
   can replace another without editing the code that uses it. A
   collaborator that is awkward to control in a test is reason enough
   for a port, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) rule
   6 says; a seam added for that reason has one adapter and the test's
   stand-ins behind it, not a family of implementations. What tips the
   balance is whether the test can make the collaborator give the answer
   it needs without a seam.

8. Rule. **Never open a production class only so a test can reach inside
   it: add no public field, getter, flag or method that only tests
   use.** What a test needs to see is either an outcome the class
   already offers its callers or a message it sends through a port.
   When it is neither, the test is checking the inside, which
   [testing object-oriented code](../oo-testing-object-oriented-code/SKILL.md)
   rule 1 forbids.

## Pattern

Before, `OpenTreatmentCourse` draws a course number with a static call
inside `run`. `CourseNumber.random()` is a static method taken to draw a
new random number on each call, so a test cannot choose the number `run`
answers, nor get the same one on a second run (rules 2 and 5).

Before:

```text
class OpenTreatmentCourse
  - courses: TreatmentCourses
  + new(courses: TreatmentCourses)
  + run(patient: PatientId): CourseNumber
    number := CourseNumber.random()
    courses.add(new TreatmentCourse(number, patient))
    return number
```

After, the number arrives through a port the class receives, and a test
can choose it.

After:

```text
interface CourseNumbers
  + next(): CourseNumber

class OpenTreatmentCourse
  - courses: TreatmentCourses
  - numbers: CourseNumbers
  + new(courses: TreatmentCourses, numbers: CourseNumbers)
  + run(patient: PatientId): CourseNumber
    number := numbers.next()
    courses.add(new TreatmentCourse(number, patient))
    return number

class FixedCourseNumbers implements CourseNumbers
  - number: CourseNumber
  + new(number: CourseNumber)
  + next(): CourseNumber
    return number
```

`TreatmentCourses` is taken to be the courses' repository port, whose
`add` stores a new course once. `new TreatmentCourse(number, patient)`
is taken to build a course for the patient under that number, a class
this fence does not declare. `CourseNumber` is a value. The adapter
behind `CourseNumbers` in the program answers a new number on each call.

`run` answers the number because it is the identifier of something just
created, which
[encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
rule 4 allows. What is stored is one `TreatmentCourse` under its
`CourseNumber`, in the clinic's database, in the transaction the
use-case object opens and ends, as
[placing domain logic](../oo-placing-domain-logic/SKILL.md) rule 2 asks.

The test builds `OpenTreatmentCourse` with an in-memory
`TreatmentCourses` and a `FixedCourseNumbers`, sends `run` once, and
checks that the answer is the chosen number and that the store holds a
course under it. Each version stores one course and asks for one number
per `run`.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A test that must build, start or reset many things to check one rule.
- A domain class that asks the machine for the time, a random number or
  a new identifier.
- A constructor that reads a file, opens a connection or starts a
  thread.
- A static call to something that writes, sends or answers differently
  each time.
- A field, getter or flag that only tests use.
- A decision and the effect it causes in one method that no test can
  reach.

## Common mistakes

- Fixing a hard test with more stand-ins instead of changing the design.
- Giving an aggregate a clock it asks once, instead of passing it the
  time.
- A port for a value or a calculation with no effects.
- Moving work out of a constructor into a setup method callers must
  remember.
- Keeping a test-only method because removing it breaks the test.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-testing-object-oriented-code](../oo-testing-object-oriented-code/SKILL.md)
  writes and names the test this skill makes possible, and its rule 1
  forbids checking the inside.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts a port beside the domain, passes collaborators in and builds the
  composition root, which rules 2, 4, 5 and 7 rely on.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  keeps an object complete from its constructor and says which parts it
  builds, which rule 4 relies on.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) keeps a
  hard edge humble, which rule 6 uses inside a class.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) gives the
  time to a transition method, which rule 3 follows.
- [oo-working-with-legacy-code](../oo-working-with-legacy-code/SKILL.md)
  gets a test around today's code before its design can improve.

## Further reading

- [Sources a test cannot repeat](references/sources-a-test-cannot-repeat.md)
- [Splitting decisions from effects](references/splitting-decisions-from-effects.md)
