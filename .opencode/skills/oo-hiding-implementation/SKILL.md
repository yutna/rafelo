---
name: oo-hiding-implementation
description: Use when many classes know how another stores or formats data, when callers must handle its internal errors, or must call its steps in order.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Hiding Implementation

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Every module should keep a secret: one design decision that is likely to
change, such as a storage layout, an algorithm or an outside system's
protocol. Callers ask for an outcome in their own words, and the module
translates at its edge. This skill draws module lines around decisions
rather than around the steps of a process, keeps each class's interface
smaller than the work behind it, and stops storage, format and errors
from crossing the line. A change to the secret then has one place to go.

## When to use

- Many classes read or write another class's storage, row or format.
- Callers handle a class's internal errors, or a database's own codes.
- Callers must send several messages in a fixed order to get one job
  done.
- A public method hands back an index, a row, a file line or a field
  order.
- Two modules must change together for one decision, such as a format
  one writes and the other reads.
- A class's interface is about as long as its code.
- A method is named for one screen, and the next caller cannot use it.

## When not to use

- The question is who may change an object's state and how:
  [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md).
- A caller reaches through a chain of objects to a collaborator:
  [limiting what an object knows](../oo-limiting-what-an-object-knows/SKILL.md).
- Two modules change together, and the question is how tightly they are
  tied or how to measure it:
  [diagnosing coupling](../oo-diagnosing-coupling/SKILL.md).
- The type only carries data, and its fields are its whole meaning:
  [deciding object or data](../oo-deciding-object-or-data/SKILL.md).

## Core rules

1. Rule. **Give each module a secret: one design decision likely to
   change, kept inside.** A storage format, an algorithm and an outside
   system's protocol are the usual secrets. Draw module lines around
   those decisions, not around the steps of a process, so that no
   caller's code depends on a decision the module may revise.

2. Default. **Make a class deep: a small interface over substantial
   work.** When callers must send several messages in a fixed order to
   get one job done, give the class one message that does the whole job.
   The callers then ask for an outcome and the class keeps how it gets
   there.

   The exception is a sequence the caller must control, such as steps a
   person confirms one at a time. Then the caller owns the pace, and the
   messages stay apart.

3. Rule. **Let nothing about the implementation cross the interface.**
   Names, parameters, results and errors speak in the caller's terms. A
   caller of `Appointments.add` never sees a table, a row or the
   database's own error code. The adapter behind the port is the only
   place that names the table, and it translates at that edge.

4. Judgement. **Decide whether a call that would change nothing fails by
   whether its caller must learn of it.** Releasing a slot that is
   already free leaves it free, as `notation.md`'s `Slot.release` does,
   because no caller acts on that. A repeated join or cancel may hide a
   caller's mistake instead, so the pack's `WaitingList.join` raises
   `AlreadyWaiting` and `Appointment.cancel` raises
   `AppointmentNotCancellable`. What tips the balance is whether a caller
   would do anything different on hearing of it.

5. Rule. **Keep one decision in one module.** When two modules must
   change together for one decision, such as a format one of them writes
   and the other reads, move that decision into one of them. The other
   sends a message and no longer spells the format.

6. Judgement. **Make an interface somewhat general: shaped for what its
   callers need across the next changes, not for one caller's screen and
   not for every caller that might exist.** What tips the balance is
   whether the next caller could use a method as it is. A method named
   for one screen leaks that screen into the module, and a method so
   general that every caller writes the same glue leaks the work back
   out.

## Pattern

Before, `DayPlan` stores a day as fifteen-minute blocks and makes every
caller work with them. `CallCentre.book` asks for an index, reads the
block and writes it, so the caller tests the block and raises the error.
After, `DayPlan` keeps the blocks and the index private and answers one
message that does the whole booking.

Before:

```text
class DayPlan
  - blocks: List<PatientId?>
  - opensAt: DateTime
  - blockLength: Duration
  + new(entries: List<PatientId?>, opensAt: DateTime,
      blockLength: Duration)
    blocks := entries.copy()
  + blockIndex(startsAt: DateTime): Int
    return startsAt.blockIndexFrom(opensAt, blockLength)
  + blockAt(index: Int): PatientId?
    return blocks.at(index)
  + setBlock(index: Int, patient: PatientId?): void
    blocks.replace(index, patient)

class CallCentre
  - plan: DayPlan
  + new(plan: DayPlan)
  + book(startsAt: DateTime, patient: PatientId): void
    raises SlotTaken
    index := plan.blockIndex(startsAt)
    if plan.blockAt(index) = null then
      plan.setBlock(index, patient)
    else
      raise SlotTaken
    return
```

After:

```text
class DayPlan
  - blocks: List<PatientId?>
  - opensAt: DateTime
  - blockLength: Duration
  + new(entries: List<PatientId?>, opensAt: DateTime,
      blockLength: Duration)
    blocks := entries.copy()
  + reserve(startsAt: DateTime, patient: PatientId): void
    raises SlotTaken
    index := indexOf(startsAt)
    if blocks.at(index) = null then
      blocks.replace(index, patient)
    else
      raise SlotTaken
    return
  + isFree(startsAt: DateTime): Boolean
    return blocks.at(indexOf(startsAt)) = null
  - indexOf(startsAt: DateTime): Int
    return startsAt.blockIndexFrom(opensAt, blockLength)

class CallCentre
  - plan: DayPlan
  + new(plan: DayPlan)
  + book(startsAt: DateTime, patient: PatientId): void
    plan.reserve(startsAt, patient)
    return
```

The block list arrives through the constructor and is copied, so a
caller that later changes its own list cannot change the plan.
`entries.copy()` makes a new list with the same entries. The opening time
and the block length arrive as constructor parameters named for their
fields, so the constructor sets both. `blocks.at(index)` is taken to mean
the entry at that position, and `blocks.replace(index, patient)` is taken
to mean that the entry at that position is replaced once.
`startsAt.blockIndexFrom(opensAt, blockLength)` is taken to mean the
position of the block of that length that begins at that time; `indexOf`
is the one private place that asks, so no caller does arithmetic.
`isFree` asks the same question as the test inside `reserve` and changes
nothing. `reserve` tests one block once, sets it once, and raises
`SlotTaken` without changing anything when it is taken. `CallCentre.book`
sends one message. A change to the block size now touches `DayPlan` and
the one place that builds it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A public method whose name or result exposes storage, such as an
  index, a row or a raw format.
- Callers that send several messages in a fixed order to get one job
  done.
- An outside system's or a database's own error handled far from the
  code that called it.
- The same format, limit or constant known in two or more modules.
- A class whose interface is about as long as its code.

## Common mistakes

- Making every field private but adding a getter and a setter for each,
  which hides nothing.
- Splitting a job into classes by the order its steps run, so each class
  knows the same format.
- Wrapping an outside library one method for one method and calling it
  hidden.
- Raising an error for a case that changes nothing, so every caller
  writes the same check.
- Making an interface general for callers that do not exist yet.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps state behind messages named for the action.
- [oo-limiting-what-an-object-knows](../oo-limiting-what-an-object-knows/SKILL.md)
  removes a chain or a middle man that hides no decision.
- [oo-diagnosing-coupling](../oo-diagnosing-coupling/SKILL.md) measures
  how tightly two parts are tied before this skill removes the tie.

## Further reading

- [Secrets and depth](references/secrets-and-depth.md)
- [Leaks](references/leaks.md)
