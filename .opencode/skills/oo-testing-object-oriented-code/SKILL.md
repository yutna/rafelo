---
name: oo-testing-object-oriented-code
description: Use when writing tests for objects, when tests break although behaviour did not change, or when choosing a mock, stub or fake.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Testing Object-Oriented Code

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A test holds a design in place while the code inside changes. It does
that only when it speaks to an object through its callers' messages and
checks what a caller could see. A test has three moves, in this order:
build what is needed, send one message, check what a caller could see. A
test that reaches inside is tied to one arrangement of the code, so a
tidy-up turns it red although the clinic sees no change. This skill
covers the moves, the names, and the stand-ins a test may use.

## When to use

- You are writing a test for a value, an entity, an aggregate or a use
  case.
- A small change inside one class turns many tests red.
- A test reads a private field, sends a private message or checks the
  order of steps inside a method.
- A test checks that a query was asked, or how many times.
- You are choosing between a dummy, a stub, a spy, a mock and a fake.
- A test is named after a method, a number, or nothing in particular.
- A collaborator is a database, a clock, a notice sender or a library
  the clinic does not own.

## When not to use

- The code cannot be built in a test without a database, a server or the
  real time, and the question is how to change its design so it can:
  that is
  [designing for testability](../oo-designing-for-testability/SKILL.md).
- The code has no tests at all and must change now: pinning what it does
  before the change is in
  [working with legacy code](../oo-working-with-legacy-code/SKILL.md).
- A screen, a scheduled job or a message listener needs its framework to
  run: [layering the system](../oo-layering-the-system/SKILL.md) rule 4
  keeps such an edge humble.
- The code is an answer used once and thrown away, which the index's
  sizing table skips entirely.

## Core rules

1. Rule. **Speak to an object only through the messages its callers
   send, and check only what one of those callers could see: the answer
   it returns, what a later public message answers, or a message it sends
   out through a port.** Reading a private field, sending a private
   message or counting the steps inside a method ties the test to one
   arrangement of the code, so a tidy-up breaks it while the clinic's
   behaviour stays the same.

2. Default. **Write each test before the code that makes it pass.** Run
   it and watch it fail for the reason its name states; write the least
   code that turns it green; then improve the design while every test
   stays green. A test that has never failed has shown nothing.
   The exception is code written only to learn something, such as a
   trial of how an outside service answers: throw that code away, and
   write the version that stays test first.

3. Rule. **Name each test for the behaviour it checks, in the clinic's
   words: the situation and the outcome.** "A booking into a taken slot
   is refused" tells a reader what broke; a number or a bare method name
   tells nothing. When a test fails, its name says which rule broke, and
   when that rule changes, the names say which tests to open.

4. Default. **Keep the real domain classes in a test, its values,
   entities and aggregates, and stand in only for a collaborator the
   object reaches through a port, such as a repository, a clock or a
   notice sender.** A real domain object behaves in the test as it does
   in the clinic; a stand-in for one repeats what the test writer
   guessed about it. The exception is a role no class plays yet, whose
   messages the test is finding out: a stand-in for that role lets the
   test say what the object needs from it, and the role becomes a port
   the domain owns, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rule 1 asks.

5. Rule. **Choose the kind of stand-in from what the test asks of the
   collaborator: a stub returns an answer the test chose to a query; a
   fake is a small working version, such as a repository that holds its
   aggregates in memory; a spy records the commands it receives for the
   test to read afterwards; a mock is told in advance which commands to
   expect and fails the test when they do not arrive; a dummy fills a
   parameter the test never uses.** Never check that a query was sent: a
   query changes nothing, as
   [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
   rule 4 asks, so asking it cannot be behaviour.

6. Judgement. **Check a command by the state it leaves or by the
   message it sends.** Check the state when an object the test can ask
   keeps the outcome, such as a waiting list that no longer holds a
   patient; check the message when the outcome leaves through a port and
   no class in the clinic keeps it, such as a notice sent to that
   patient. What tips the balance is where the outcome lives: checking
   messages for an outcome kept as state ties the test to the steps that
   reach it.

7. Rule. **Never stand in for a type the clinic's code does not own,
   such as a library's client or an outside system's own class: put a
   port the clinic owns in front of it, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rule 1 asks, and stand in for the port.** A stand-in for a type the
   clinic does not own repeats a guess about how that type behaves, and
   the tests pass while the real one fails. The adapter that answers the
   port is checked against the real outside system in a few slower
   tests, and a fake for the same port passes those same tests, so the
   two cannot drift apart.

## Pattern

Both fences test one step of the aggregates reference: a cancelled
appointment frees a slot, and `FreedTimeOffer` offers it to the patient
who has waited longest. `FreedTimeOffer` itself is that reference's
class, unchanged; this skill tests it and adds nothing to it.

Before, the test replaces the waiting list with a subclass, so the real
`WaitingList` never runs.

Before:

```text
class ScriptedWaitingList extends WaitingList
  - next: PatientId
  - asked: Boolean
  - removed: PatientId?
  + new(next: PatientId)
    asked := false
    removed := null
  + nextPatient(): PatientId?
    asked := true
    return next
  + remove(patient: PatientId): void
    removed := patient
    return
  + wasAsked(): Boolean
    return asked
  + removedPatient(): PatientId?
    return removed
```

The test builds `ScriptedWaitingList` with one patient, hands
`FreedTimeOffer` the notices stand-in the After fence declares, runs
`run`, and checks `wasAsked()` and `removedPatient()`. It checks that a
query was asked (rule 5) and stands in for a domain class (rule 4), so
it fails if `run` stops asking `nextPatient` although nothing a caller
sees changes, and it passes while the real `WaitingList.remove` is
broken, because the real class never runs. The stand-in reads none of
the fields it inherits, because it overrides every message
`FreedTimeOffer` sends to the list.

After, the test keeps the real waiting list and records the notice at
the port.

After:

```text
interface Notices
  + send(patient: PatientId, slot: Slot): void

class RecordingNotices implements Notices
  - sent: List<PatientId>
  + new()
    sent := new List<PatientId>()
  + send(patient: PatientId, slot: Slot): void
    sent.add(patient)
    return
  + sentTo(): ReadOnlyList<PatientId>
    return sent.readOnlyView()
```

`Notices` keeps the shape its senders give it in the aggregates
reference, `send(patient, slot)`, and this fence declares only `send`
because `FreedTimeOffer` sends only `send`. `WaitingList` is the real
class, with the fields, constructor, `join` and `waiting` of the
composition skill and the `nextPatient` and `remove` of the aggregates
reference. The test builds a real `WaitingList`, sends it `join` for one
patient, passes a cancelled appointment, whose `freedSlot()` the
aggregates reference takes to answer the slot it released, runs `run`,
and checks two things: `sentTo()` contains the patient, the message that
leaves through the port (rule 6), and `waiting()` no longer contains the
patient, the state the list keeps (rule 6). `RecordingNotices` is a spy
(rule 5) for a port the clinic owns (rule 7). `new List<PatientId>()` is
taken to mean an empty list that the notices stand-in owns. `true` and
`false` are the two values a `Boolean` holds. Both fences store nothing,
and the caller that saves the list after `run` is left out.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A test that reads a private field or sends a private message.
- A test that checks a query was asked, or how many times.
- A stand-in that extends a concrete domain class.
- A stand-in for a library's or an outside system's own type.
- Test names such as `test1` or the name of the method alone.
- A test that fails when a method is renamed inside the class.

## Common mistakes

- Writing the test after the code and never seeing it fail.
- Replacing values and entities with stand-ins because they have
  collaborators.
- Checking every message an object sends, instead of its outcome.
- Keeping a fake that no test compares with the real adapter.
- Putting several behaviours in one test, so its failure names none.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps a query from changing state, which rule 5 relies on.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts a port beside the domain and an adapter at the edge, which rules
  4 and 7 rely on.
- [oo-designing-interfaces](../oo-designing-interfaces/SKILL.md) shapes
  the port a stand-in answers around the messages its caller sends.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) keeps a
  hard edge humble, which is why a screen or a job is not tested in
  depth here.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) gives
  the freed-time step this skill's Pattern tests, and the waiting list
  it changes.
- [oo-designing-for-testability](../oo-designing-for-testability/SKILL.md)
  changes a design that a test cannot build or control.
- [oo-working-with-legacy-code](../oo-working-with-legacy-code/SKILL.md)
  pins what untested code does before it changes.

## Further reading

- [Stand-ins](references/stand-ins.md)
- [Test names and shape](references/test-names-and-shape.md)
