---
name: oo-documenting-design-decisions
description: Use when nobody remembers why a design is this way, when a choice is costly to reverse, or before drawing a picture of the system for a redesign.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Documenting Design Decisions

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A design carries choices that the code cannot explain. When the reason
for one of them lives only in a chat thread or in one person's memory,
every later reader pays to rediscover it. This skill writes that reason
down as a short record in the repository, keeps an accepted record
intact by writing a new one that supersedes it, and draws a picture only
where a picture shows what the code cannot show quickly. A record and a
picture are dated, so a later reader can tell what the code has
outgrown.

## When to use

- Nobody remembers why a design is shaped this way, and the repository
  does not say.
- A choice is costly to reverse, such as where the clinic keeps its
  clinical photographs.
- A change reaches across modules, and the next reader will ask why.
- A team is about to draw a picture of the system for a redesign.
- A picture no longer matches the code it describes.
- A decision changes course and an accepted record covers the old
  choice.

## When not to use

- A comment beside one line or one method is the question: that is
  [commenting what code cannot say](../oo-commenting-what-code-cannot/SKILL.md).
- The decision is local to one class and cheap to undo, such as a private
  method's name: the code and its review carry all a reader needs.
- The question is where one team's model ends and another's begins,
  which [bounding contexts](../oo-bounding-contexts/SKILL.md) rule 3
  writes down as a context map.
- The request is for a complete picture notation, or for diagrams
  generated from the code: outside this skill.

## Core rules

1. Default. **Write a decision record for a choice that is costly to
   reverse, that reaches across modules, or that people keep asking
   about, such as where the clinic keeps its clinical photographs.** The
   record answers what the code cannot: why the design took this shape
   instead of another.
   The exception is a choice whose rule the code already states where a
   reader naturally looks, such as a value type that enforces it or a
   test named after it: such a choice needs no record.

2. Rule. **Give each record a number, a title, a date, a status, the
   context as it stood on that day, the options weighed, the choice,
   and the consequences accepted, the costs included, and keep it as a
   short file in the repository, beside the code it shapes.** A record
   that stops at the choice tells a reader no more than the code does;
   the next reader needs the options and what each of them cost. Kept in
   the repository, the record changes in the same review as the code.

3. Rule. **Never rewrite the decision of an accepted record: when the
   clinic changes course, write a new record that supersedes it, change
   only the old record's status to name the new one, and link the two
   both ways.** Leave the old context and options untouched: the reasons
   the first choice once made sense are part of the reasons the second
   one now does.

4. Judgement. **Draw a picture only when it shows what the code cannot
   show quickly: which parts talk to which across module or system
   boundaries, one flow that passes through several objects, or the
   states of a lifecycle.** The test is how many files a reader would
   have to open to learn the same thing. A picture of what one file or
   one folder already shows is a second copy that must be kept true.

5. Default. **Keep each picture at one level: the system among the
   people and the other systems it works with, the parts of the system
   that are deployed on their own, the modules inside one deployed part,
   or the classes of one small knot of code.** A picture that puts a
   table, a partner's system and a class on the same canvas answers no
   question well.
   The exception is a single request traced from the person who starts
   it through to the store that keeps its result, drawn as a numbered
   list of steps across levels.

6. Rule. **Treat a picture as a dated sketch of the code, never as its
   source: keep it beside the record or the code it explains, and redraw
   or delete it in the change that makes it wrong.** Where a picture and
   the code disagree, the code is what runs; correct or delete the
   picture, and never change the code to match the drawing.

## Pattern

Before, the class keeps a costly choice, and the options weighed for it,
in a comment block that no code review reads and that grows each time
someone questions the choice (rules 1 and 2).

Before:

```text
class PhotoArchive implements ClinicalPhotos
  -- Photos were rows in the clinic database until the
  -- nightly backup ran into the morning. We tried the
  -- imaging supplier's archive next, but it kept no link
  -- to the visit, so photos now go to the file store under
  -- their own id and the database keeps only that id.
  -- Ask the records lead before you change any of this.
  - files: FileStore
  + new(files: FileStore)
  + add(photo: ClinicalPhoto): void
    files.write(photo.id(), photo.content())
```

After:

```text
class PhotoArchive implements ClinicalPhotos
  -- why photos live in a file store: decision record 12
  - files: FileStore
  + new(files: FileStore)
  + add(photo: ClinicalPhoto): void
    files.write(photo.id(), photo.content())
```

After, the class stays as it was, with the same field, constructor and
`add`; the history moves to decision record 12, shown in full in
[decision records](references/decision-records.md), and a single line in
the code points a reader to it (rule 2).

Take `ClinicalPhotos` as the domain's port for photographs, of which the
fences show only `add`. Take `FileStore` to write the given content once
under the given key. `photo.id()` answers the photograph's identifier
and `photo.content()` its image.

What is stored: the photograph's content, under its identifier, in the
file store, written by `add`. The visit's row that keeps the identifier
is stored later by the use case, in the transaction it opens and ends;
the fences leave that out. Each version writes one file per `add`: the
constructor sets the field before `add` reads it, and `add` sends one
`write`.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A costly choice whose only explanation sits in a chat thread or in
  one person's head.
- A record that was accepted and later edited to say something
  different.
- A record that states the choice and stops there, with no options and
  no consequences.
- A picture with no date, or one stored where a code review never
  visits.
- One picture that shows a table, an outside system and a class at
  once.
- A comment block that narrates how a decision was reached.

## Common mistakes

- Writing a record for each small choice, until the costly ones are lost
  among them.
- Deleting the record that a new one supersedes, rather than changing
  its status.
- Drawing a module's every class when its file list already lists them.
- Writing the context as it looks now, not as it looked on the day.
- Letting a picture rule the design, then changing code until it
  matches.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) rule 3, for
  the context map.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) rule 1,
  for a lifecycle written before its code.
- [oo-organising-modules](../oo-organising-modules/SKILL.md) rule 1,
  for business capabilities as top-level modules.
- [oo-commenting-what-code-cannot](../oo-commenting-what-code-cannot/SKILL.md)
  decides what a comment beside the code says, and keeps a decision's
  history in its record.

## Further reading

- [Decision records](references/decision-records.md)
- [Choosing a picture](references/choosing-a-picture.md)
