---
name: oo-designing-aggregates
description: Use when choosing what one transaction keeps consistent, when two people saving at the same time break it, or one load pulls in too much.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Aggregates

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

An aggregate is the set of objects that one rule must keep true at every
change. It has one root entity, and every change inside it goes through
that root. This skill draws the boundary around the rule, keeps inner
objects private, refers to other aggregates by identity, and decides
where a rule that spans aggregates is brought true. The aim is the
smallest aggregate that still keeps each rule true when the change
commits: one transaction changes one aggregate, and a rule that can wait
is brought true soon after.

## When to use

- A rule must hold over several objects at once, and it is unclear which
  objects one transaction keeps consistent.
- Two people save at the same time, and one save fails or overwrites the
  other's change.
- One small change loads far more of the clinic than it needs.
- A field is about to hold another object where only its identity is
  used.
- A rule reads many aggregates, such as a unique health number, and
  needs a home.
- A review asks what one transaction keeps consistent.

## When not to use

- The change touches one object, and no rule involves any other object.
- Nothing runs at the same time as the change, such as a one-off import
  script that runs alone, and no rule spans objects.
- The question is which class owns one behaviour, not which objects must
  change together: that is assigning responsibilities.

## Core rules

1. Rule. **Draw an aggregate around the objects that one rule must keep
   true at every change, and give it one root entity.** A group class
   and the patients enrolled in it form one aggregate when no change may
   leave more patients enrolled than the room holds: the rule covers the
   whole group, so the group and its enrolments change together. Objects
   that are related, shown on one screen or loaded together do not belong
   in one aggregate for those reasons alone; the rule that must hold at
   once decides.

2. Rule. **Change what is inside an aggregate only by sending messages
   to its root.** Outside code holds a reference to the root alone, the
   root keeps its rule on every change, and an inner object is never
   handed out to be changed. A caller that must read inner objects gets
   values or a read-only view, as rule 5 of encapsulating state and
   behaviour asks.

3. Rule. **Refer to another aggregate by its identity, not by holding
   its object.** A group class holds the `ClinicianId` of the clinician
   who leads it, not the `Clinician`. Holding the object would let one
   change reach into two aggregates, and would load one aggregate with
   the other. Code that needs the other aggregate loads it by that
   identity.

4. Default. **Change one aggregate in one transaction.** A rule that
   spans two aggregates is either kept true at once, which puts them in
   one aggregate (rule 1), or brought true soon after the first change
   commits, by a later step that reacts to it.

   The exception is a change that creates one aggregate while it changes
   another, such as booking, which reserves a slot and creates its
   appointment: nobody else can be changing the new one, and a conflict
   on the other should refuse the whole change, so one transaction may
   cover both when one store commits them, opened in one place that says
   why.

5. Judgement. **Keep an aggregate as small as its rules allow.** A large
   aggregate loads more than most changes need, and unrelated changes by
   two people collide. A small one leaves more rules to be brought true
   across aggregates later (rule 4). What tips the balance is whether the
   business needs the rule true at the moment of every change, or can
   accept it true a little later and repaired when it is not.

6. Judgement. **Check a rule over many aggregates, such as no two
   patients sharing a health number, outside any one of them, never by
   loading them all into one.** What tips the balance is the cost of a
   rare breach: when it must never happen, the store's own uniqueness
   check refuses the second save; when a rare one can be fixed by hand, a
   check before the change and a later report are enough.

## Pattern

Before, the enrolment rule lives in a use case that reads the session's
list and changes it. After, the session keeps the rule, and the use case
only asks it to enrol the patient.

Before:

```text
class GroupSession
  - id: GroupSessionId
  - leader: Clinician
  - capacity: Capacity
  - attendees: List<PatientId>
  + new(id: GroupSessionId, leader: Clinician, capacity: Capacity)
    attendees := new List<PatientId>()
  + attendees(): List<PatientId>
    return attendees
  + capacity(): Capacity
    return capacity

class EnrolPatient
  + run(session: GroupSession, patient: PatientId): void
    raises SessionFull
    if session.capacity().isReachedBy(session.attendees()) then
      raise SessionFull
    else
      session.attendees().add(patient)
    return
```

`new List<PatientId>()` is taken to mean an empty list the session owns.
The constructor sets `id`, `leader` and `capacity` from its parameters,
and sets `attendees` before any method reads it. Both methods return the
field itself, so any holder of the list can add to it.
`EnrolPatient.run` reads the capacity and the list, checks the rule, and
`session.attendees().add(patient)` appends once when the room is not
full. `Capacity.isReachedBy(attendees)` is taken to mean that the list
holds as many patients as the capacity allows.

After:

```text
class GroupSession
  - id: GroupSessionId
  - leader: ClinicianId
  - capacity: Capacity
  - attendees: List<PatientId>
  + new(id: GroupSessionId, leader: ClinicianId, capacity: Capacity)
    attendees := new List<PatientId>()
  + enrol(patient: PatientId): void
    raises SessionFull
    if capacity.isReachedBy(attendees) then
      raise SessionFull
    else
      attendees.add(patient)
    return

class EnrolPatient
  + run(session: GroupSession, patient: PatientId): void
    session.enrol(patient)
    return
```

The constructor sets `attendees` before `enrol` reads it, and no method
returns a field. `Capacity.isReachedBy(attendees)` is taken to mean that
the list holds as many patients as the capacity allows; it compares the
list's size with the capacity. `enrol` raises `SessionFull` without
appending when the room is full, and sends `attendees.add(patient)` once
otherwise. `EnrolPatient.run` sends one message and decides nothing. When
a store saves the session whole and refuses a save made from an older
copy, the second of two enrolments for the last place fails.

The examples in `notation.md` and `oo-limiting-what-an-object-knows` show
a slot's syntax or another rule, not a boundary: once a slot is its own
aggregate, an appointment holds its identity (rule 3), booking, which
reserves a slot and creates an appointment at once, is rule 4's
exception, and the slot's release when an appointment is cancelled, which
`notation.md`'s `cancel` does in the same call, becomes rule 4's later
step.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A rule checked in a use case or a service by reading another object's
  collection and then changing it.
- A method that returns an inner collection or entity that callers then
  change.
- A field that holds another aggregate's object where only its identity
  is used.
- One transaction that changes several aggregates, with nothing saying
  why.
- A small change that loads hundreds of other objects.
- Save conflicts between people who changed unrelated parts of one
  object.

## Common mistakes

- Drawing the boundary around everything that is related, or shown on
  one screen.
- Giving every entity its own aggregate, so rules that must hold at once
  are spread across transactions.
- Reaching an inner object through the root and changing it from outside.
- Loading many aggregates into one to check a uniqueness rule.
- Treating the later step that brings a rule true as optional, so its
  failures go unnoticed.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)
  makes an identifier a value that can name another aggregate.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  keeps inner objects behind messages and hands out a read-only view.
- [oo-speaking-the-domain-language](../oo-speaking-the-domain-language/SKILL.md)
  finds the clinic's words for the rule an aggregate keeps.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  starts the later step of rule 4 once the change commits.

## Further reading

- [Finding the boundary](references/finding-the-boundary.md)
- [Consistency across aggregates](references/consistency-across-aggregates.md)
