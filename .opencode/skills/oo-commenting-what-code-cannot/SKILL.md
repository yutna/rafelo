---
name: oo-commenting-what-code-cannot
description: Use when comments or notes repeat the code or contradict it, or when a note must explain a reason or a warning no well-chosen name can explain.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Commenting What Code Cannot Say

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Code carries most of what a reader needs: a name says what a class or
method is for, a value type holds a rule, and a test names a behaviour.
This skill keeps the small remainder honest. It puts a reason, an outside
constraint, a trade-off or a warning in a comment only where no name,
type or test can carry it, deletes the comments that repeat what the code
already says, and treats a comment that disagrees with the code as a
defect in the change that finds it. Every comment it keeps describes the
code as it is now.

## When to use

- A comment restates the name or the signature beside it.
- A comment disagrees with the code, and a reader cannot tell which one
  is right.
- A comment block lists who changed the code and when, or what it
  replaced.
- Code no longer used sits commented out in the file.
- A reader asks why a line takes the longer road, or what limit another
  system or organisation sets.
- A comment is about to explain a name that could say the same thing.
- A surprising behaviour needs either a comment or a test.

## When not to use

- The question is why a choice that reaches across modules was made, and
  where its record lives: that is
  [documenting design decisions](../oo-documenting-design-decisions/SKILL.md).
- The question is what a class or method should be called: that is
  [naming classes and methods](../oo-naming-classes-and-methods/SKILL.md).
- The question is what a type's contract must promise so that every
  subtype keeps it: that is
  [honouring substitutability](../oo-honouring-substitutability/SKILL.md).
- The text is for people who do not read the code, such as a guide for
  receptionists or the reference of a published interface: outside this
  skill.

## Core rules

1. Rule. **Say it in the code first, and comment only what is left: a
   name that says what a class or method is for, as naming classes and
   methods, rules 1 to 3, asks; a value type for a primitive that carries
   a rule, as modeling values and entities, rule 5, asks; a method named
   for a step that needed a comment; or a test named for a behaviour.**
   Each of those carries its meaning where a reader meets it, so no
   second text has to be kept true. A comment comes after them, and only
   for what none of them can hold.

2. Rule. **Comment why, not what: a reason the code cannot show, a
   constraint from outside the code, such as what another system accepts,
   a trade-off the team chose, or a warning about a consequence a reader
   would not expect.** A comment that describes the next line competes
   with it: a reader follows the note and skips the line, and the note
   goes stale when the line changes. Keep the note beside the code it
   explains, short enough to read in one pass.

3. Rule. **Treat a comment that disagrees with the code as a defect, and
   fix it in the change that finds it: find out which one is right, from
   the people who own the rule or from a test, then correct the comment
   or the code, and add a test when the code was wrong.** Leave neither
   the wrong note nor the wrong line for a later change. A note corrected
   to match a defect teaches every reader the defect.

4. Default. **Delete a comment that repeats what the code already says,
   such as a comment naming the constructor above it.** A second copy of
   one fact is one more copy to keep true, and it is the copy that drifts
   first.
   The exception is the contract under a public method's signature,
   where honouring substitutability, rule 4, asks for one: callers read
   the contract instead of the body, so it stays even where the body
   happens to show the same thing.

5. Rule. **Keep history out of comments: who changed a line, when, and
   what it replaced belong to version control; a choice's reasons and the
   options weighed belong to its decision record, as documenting design
   decisions, rule 2, keeps them; and code no longer used is deleted, not
   commented out.** Read the note as a statement about the code in front
   of you, with one line at most naming the record that gives the reasons.

6. Judgement. **Choose between a comment and a test for a behaviour that
   would surprise a reader.** A test named for the behaviour fails when
   the behaviour changes, where a comment stays quiet through the same
   change. A comment can still carry a reason no test can show, such as a
   limit another organisation sets. What tips the balance is whether a
   test can show the behaviour: when it can, write the test, and keep at
   most a one-line reason beside the code.

## Pattern

`HostedVideoRooms` is the adapter behind the clinic's `VideoRooms` port
for telehealth visits, and the one class that knows the provider's
client (crossing system boundaries, rule 3), so the outside constraint
is written here and on no domain class.

Before:

```text
class HostedVideoRooms implements VideoRooms
  - provider: VideoProvider
  -- the constructor
  + new(provider: VideoProvider)
  -- opens one room per patient for the whole day
  + roomFor(visit: VisitId): RoomLink
    return RoomLink.at(provider.openRoom(visit.text()))
```

In the Before, "the constructor" repeats the code beside it (rule 4),
and "one room per patient for the whole day" disagrees with it: `roomFor`
opens a room for a visit, so the code is right (rule 3).

After:

```text
class HostedVideoRooms implements VideoRooms
  - provider: VideoProvider
  + new(provider: VideoProvider)
  -- the provider closes a room once its host leaves, so a
  -- room is opened for one visit, never kept for the day
  + roomFor(visit: VisitId): RoomLink
    return RoomLink.at(provider.openRoom(visit.text()))
```

After, both notes are gone. The first is deleted (rule 4), and the
second, once corrected, would only repeat the signature, so it is
deleted too (rules 3 and 4). The comment that stays sits above the
method, where the Before's comments sat, and gives the reason a room
serves one visit: the provider closes a room once its host leaves. That
is the provider's behaviour, which no name in the clinic's code can
carry (rule 2). It is a note for the adapter's maintainers, not a
contract under the signature, which honouring substitutability, rule 4,
places there for callers.

`VideoProvider` is taken to be the provider's client, whose `openRoom`
takes the visit's identifier as text and answers the room's address as
text. `visit.text()` answers the identifier as text, `RoomLink.at` is
taken to be the named factory of the clinic's `RoomLink` value, and
`VisitId` is the visit's identity, as the antipatterns skill uses it.
`openRoom` is taken to raise nothing, and the provider's failures are
left out of the fences.

The fences store nothing. Each version opens one room per `roomFor`: the
constructor sets `provider` before `roomFor` reads it, and each `roomFor`
sends one `openRoom`.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A comment above each line that says what the line does.
- A comment whose number, name or order differs from the code beside it.
- Code commented out and left in place.
- A comment that lists who changed the code and when.
- A long comment that explains what a badly named method does.

## Common mistakes

- Writing a comment to explain a name instead of changing the name.
- Fixing the code and leaving the old comment beside it.
- Deleting a comment that held an outside constraint along with the
  noise.
- Keeping a decision's history in a block of comments.
- Commenting a surprising behaviour that a test could show.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-documenting-design-decisions](../oo-documenting-design-decisions/SKILL.md)
  rule 2 keeps a choice's reasons and the options weighed in a record.
- [oo-naming-classes-and-methods](../oo-naming-classes-and-methods/SKILL.md)
  rules 1 to 3 choose the name that makes a comment unnecessary.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)
  rule 5 replaces a primitive that carries a rule with a value type.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  rule 4 places a contract where callers read it.
- [oo-testing-object-oriented-code](../oo-testing-object-oriented-code/SKILL.md)
  names a test for the behaviour it shows.

## Further reading

- [Comments worth keeping](references/comments-worth-keeping.md)
