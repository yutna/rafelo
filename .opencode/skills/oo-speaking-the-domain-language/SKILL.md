---
name: oo-speaking-the-domain-language
description: Use when code words differ from what staff say, when staff talk about something no class models, or two teams mean different things by one word.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Speaking the Domain Language

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

The words in the code are the words the staff will use when they talk
about the code. When the two vocabularies drift apart, every
conversation needs a translation and every rule needs a comment. This
skill keeps one vocabulary: classes, methods and events take the words
the people who do the work already use, a concept they rely on gets a
type or a method of its own, and a word with two meanings becomes two
concepts. It also keeps the vocabulary of storage, transport and
frameworks outside the domain model.

Choosing the grammar of a name is a separate question, and this skill
leaves it to naming classes and methods. The aim here is the word, not
its form.

## When to use

- Reception, nursing or billing uses a word the code spells differently.
- The staff describe a step or a thing that no class or method models.
- Two teams use one word for different things.
- A field's meaning depends on a comment, a status number or a flag.
- A domain class carries a storage or framework word in its name.

## When not to use

- The only question is how to phrase a name, such as a noun for a class,
  a verb for a command or a Manager suffix, and no domain word is in
  dispute: that is naming classes and methods.
- The code is already split into separately owned parts, each with its
  own model, and the question is where the line between them runs or how
  they translate at it.
- The words come from an outside standard the code must match, such as
  the field names of a message format or a coding scheme the clinic does
  not own.

## Core rules

1. Rule. **Name a class, a method or an event with the same word the
   people who do the work use for it.** If reception says a patient
   *checks in*, the code says `checkIn`; if the nurses say a patient
   *missed* an appointment, the code says `recordNoShow`, not
   `updateState(2)` or `flagAbsent`. Code that needs a translation table
   before it can be discussed with the staff is where misunderstandings
   hide. Whether a name should be a noun for a class or a verb for a
   command is a question for rules 1 and 2 of naming classes and
   methods.

2. Default. **When the staff talk about something the code has no class
   or method for, give it one.** A *recall* that lives only as a flag, a
   date field and a comment becomes a type or a method with that name,
   holding its own rule; a *double booking* stored the same way becomes
   the operation that refuses the second booking. The staff use the word
   because they decide something with it, and code that stores the
   pieces without the concept leaves that decision scattered.

   The exception is a word that names nothing the code decides on, such
   as a label printed on a report: it stays data.

3. Judgement. **Find the words by walking through the work with the
   people who do it, one event at a time.** This is event storming:
   write down what happens, in the past tense (*appointment booked*,
   *patient checked in*), then the request that causes each event, who
   makes it, and the rule that can refuse it. Each event, request and
   rule is a candidate name for an event, a method and a check in the
   code. What tips the balance is how much of the process the team
   cannot yet name: a walkthrough pays off for a new or disputed
   process, while for a small change the staff's own forms and messages
   give the words.

4. Rule. **When two groups use one word for two different things, keep
   two concepts in the code.** Never let one class serve both meanings
   through flags or optional fields: to reception an *appointment* is a
   booked slot, while to billing it is a billable visit. Where the two
   meanings share code, each gets its own word, as rule 4 of naming
   classes and methods describes. Where each group's code is already
   separate, [bounding contexts](../oo-bounding-contexts/SKILL.md) draws
   the line between them.

5. Default. **When the code's word for a thing differs from the staff's,
   change the code to the staff's word in the change that finds the
   difference.** Use that word in tests and in the team's talk too, so
   one vocabulary covers both the work and the code; a name other
   systems depend on keeps the exception to rule 6 of naming classes and
   methods.

   The exception is a word the staff themselves use vaguely or for two
   things: agree a sharper word with them, write it down beside the
   code, and use that one everywhere.

6. Rule. **Keep storage, transport and framework words out of the domain
   model.** `PatientDto`, `AppointmentEntity`, `SlotRow` and
   `BookingJson` belong at the edge that talks to that storage or
   framework, while the domain classes are `Patient`, `Appointment` and
   `Slot`. The class at that edge takes the outside system's name, as
   rule 3 of naming classes and methods allows for an adapter. A
   technical word inside the model hides the staff's words and ties the
   model to one way of storing it.

## Pattern

Before, `FollowUpTask` holds the recall as a boolean flag and a comment
explains what the flag means. After, `Recall` names the concept, its
fields say what it holds, and booking an appointment is an action it
refuses a second time.

Before:

```text
class FollowUpTask
  - patient: PatientId
  - due: Date
  - flag: Boolean
  -- the flag means the recall has been booked
  + new(patient: PatientId, due: Date)
    flag := false
  + update(): void
    flag := true
```

After:

```text
class Recall
  - patient: PatientId
  - dueOn: Date
  - booking: AppointmentId?
  + new(patient: PatientId, dueOn: Date)
    booking := null
  + book(appointment: AppointmentId): void
    raises RecallAlreadyBooked
    if booking = null then
      booking := appointment
    else
      raise RecallAlreadyBooked
    return
```

`true` and `false` are taken to mean the two values a `Boolean` can
hold, and `null` is the absent value of an optional field.
`FollowUpTask`'s constructor sets `flag` once, and `update` sets it
once; `patient` and `due` come from the constructor's parameters.
`Recall`'s constructor sets `booking` once, and `book` reads it once
and sets it once when it is empty. `RecallAlreadyBooked` is raised the
way `Slot.reserve` raises `SlotTaken` in the notation. No field is read
before it is set, and no step runs twice.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A class, method or field name the staff would not recognise for a
  thing they talk about every day.
- A status number or code, such as `status = 4`, that people translate
  into a word in meetings.
- A comment that explains in the staff's words what a field means.
- One class with fields or flags that only one team ever reads.
- A storage or framework word, such as Dto, Entity, Row or Json, in a
  domain class's name.

## Common mistakes

- Inventing a technical word for a concept the staff already have a word
  for.
- Merging two teams' meanings of one word into one class with a flag for
  each.
- Agreeing a new word with the staff and leaving the code on the old
  one.
- Keeping a glossary the code no longer matches.
- Copying the staff's word for something that is really two things,
  without asking which one they mean.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-naming-classes-and-methods](../oo-naming-classes-and-methods/SKILL.md)
  chooses the grammar of a name and keeps one word for one concept.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  finds the owner of a concept once the concept has a name.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) draws the
  line between separately owned models.

## Further reading

- [Walking through the work](references/walking-through-the-work.md)
- [Two meanings of one word](references/two-meanings-of-one-word.md)
