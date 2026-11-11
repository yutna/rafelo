---
name: oo-choosing-a-pattern
description: Use when picking a design pattern for a problem, when a pattern was added before its problem, or when deciding if a pattern still pays its way.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Choosing a Pattern

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A pattern is a named arrangement that answers a problem which returns.
It earns its place only when the problem is in the code now: a second
case has arrived, a change keeps coming back, or a duplication has
already drifted apart, or when the business has named the variation with
a reason. This skill starts from the symptom, checks the pattern's force
with evidence, weighs its cost against what it removes, and takes the
pattern out again when the force goes.

## When to use

- A symptom in the code needs a name, such as a copied step or a choice
  that keeps changing, and you are choosing a pattern for it.
- A pattern was added before the code showed its force, and the team is
  deciding what to keep.
- A module is hard to change and a pattern is proposed as the answer.
- A pattern is still in the code after its last variant has gone.
- A design review asks whether a pattern pays its way.

## When not to use

- The code has one case and no duplication, and nobody has named a
  change that recurs: no pattern is needed. Build the one case and look
  again when a second arrives.
- The question is how a known force is treated, such as a status that
  changes an object's behaviour or a complex construction: the skill
  that owns the force answers it, such as
  [modeling lifecycles](../oo-modeling-lifecycles/SKILL.md),
  [replacing conditionals with
  polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  or [constructing valid
  objects](../oo-constructing-valid-objects/SKILL.md).
- The question is whether the language already provides the pattern as
  a feature. That is a question about a feature the language offers,
  which [patterns the language
  provides](../oo-patterns-the-language-provides/SKILL.md) decides.
- The question is a pattern's syntax in one programming language. That
  is outside this skill.

## Core rules

1. Rule. **Start from the symptom in the code, never from a pattern:
   name what is duplicated, what keeps changing, or what is hard to
   test, and look up the patterns that answer that symptom.** A pattern
   chosen first goes looking for a problem. A copied cancellation line
   in two channels is a symptom; start there, and
   [the catalogue](references/patterns-by-problem.md) names the
   decoration that removes the copy.

2. Rule. **Add a pattern only when its force is present in the code
   now, with evidence, such as a second case that has arrived, a change
   that keeps coming back, or a duplication that has already drifted
   apart, or when the business has named the variation with a
   reason.** That is what [encapsulating what
   varies](../oo-encapsulating-what-varies/SKILL.md) rules 1 and 4 ask
   for before any seam. A pattern without that evidence is a guess
   about a change nobody has seen.

3. Rule. **Weigh a pattern's cost before adding it: the classes and the
   indirection it adds, and the name every reader must then know.** Add
   it when that cost is smaller than the duplication or the repeated
   change it removes. A decorator costs one wrapper class and one line
   at the composition root; it pays when three channels would otherwise
   copy the same step.

4. Default. **Reach first for the plainest construct that resolves the
   force: a value, a function or a feature the language offers before a
   hierarchy of classes.** A value or a function is cheaper to read than
   an interface and a class per case.

   The exception is a force the module already answers with a pattern:
   follow the module's choice, so one force has one answer in it.

5. Default. **Build a pattern in the clinic's words: its classes keep
   domain names, such as `CancelLineChannel` rather than
   `ChannelDecorator`, as [naming classes and
   methods](../oo-naming-classes-and-methods/SKILL.md) rule 1 asks, and
   the pattern's name goes where it helps a reader, such as the design
   notes.** The name by which callers meet the class is the clinic's
   concept, not the mechanism.

   The exception is a class whose job is the mechanism itself, such as
   an adapter for an outside system or a repository: its pattern word
   is its meaning, as the exception to naming classes and methods,
   rule 3, and [designing
   repositories](../oo-designing-repositories/SKILL.md) rule 1 allow.

6. Rule. **Remove a pattern when its force has gone: a strategy with
   one implementation left, or a factory that builds one type, becomes
   a direct construction again; an observer with one listener in the
   same module becomes a direct message when its reaction must happen
   at once, while one whose reaction runs after the change commits
   stays an event, as [publishing domain
   events](../oo-publishing-domain-events/SKILL.md) rule 6 decides.**
   Keeping the machinery after the variation ends leaves a reader to
   learn a name that buys nothing.

## Pattern

Before, every reminder channel adds the clinic's how-to-cancel line
itself. The same step is copied into `EmailChannel` and `TextChannel`,
and a third channel would copy it again.

Before:

```text
value Reminder
  - patient: PatientId
  - text: String
  - mobile: String?
  + new(patient: PatientId, text: String, mobile: String?)
  + patient(): PatientId
    return patient
  + text(): String
    return text
  + mobile(): String?
    return mobile
  + withFooter(line: String): Reminder
    return new Reminder(patient, text.appendLine(line), mobile)

interface ReminderChannel
  + send(reminder: Reminder): void
    -- delivers the reminder or hands it on, and raises nothing

class EmailChannel implements ReminderChannel
  - mailer: Mailer
  - cancelLine: String
  + new(mailer: Mailer, cancelLine: String)
  + send(reminder: Reminder): void
    mailer.send(reminder.patient(), reminder.withFooter(cancelLine).text())
    return

class TextChannel implements ReminderChannel
  - gateway: TextGateway
  - cancelLine: String
  + new(gateway: TextGateway, cancelLine: String)
  + send(reminder: Reminder): void
    gateway.sendText(reminder.patient(), reminder.withFooter(cancelLine).text())
    return
```

`EmailChannel` here is the substitutability skill's class with a
`cancelLine` field and a constructor parameter added; its `send`
signature and `mailer` field are that skill's, and the line it adds is
the copy this Before shows. `Reminder` and `ReminderChannel` are that
skill's, apart from one message this skill adds. `withFooter(line)` is
a message this skill adds to `Reminder`, taken to answer a copy of the
reminder with that line added at its end; `text.appendLine(line)` is
taken to answer the reminder's text with the line added at its end.
`TextChannel` and `TextGateway` are new here. `Mailer.send` and
`TextGateway.sendText` are taken to send one email and one text. The
fence stores nothing.

After, one class adds the line around any channel. `EmailChannel` is the
substitutability skill's class exactly; `TextChannel` holds only its
gateway, and both send the reminder they are given. `CancelLineChannel`
adds the line and hands the reminder on, so a third channel needs no copy
of the step.

After:

```text
value Reminder
  - patient: PatientId
  - text: String
  - mobile: String?
  + new(patient: PatientId, text: String, mobile: String?)
  + patient(): PatientId
    return patient
  + text(): String
    return text
  + mobile(): String?
    return mobile
  + withFooter(line: String): Reminder
    return new Reminder(patient, text.appendLine(line), mobile)

interface ReminderChannel
  + send(reminder: Reminder): void
    -- delivers the reminder or hands it on, and raises nothing

class EmailChannel implements ReminderChannel
  - mailer: Mailer
  + new(mailer: Mailer)
  + send(reminder: Reminder): void
    mailer.send(reminder.patient(), reminder.text())
    return

class TextChannel implements ReminderChannel
  - gateway: TextGateway
  + new(gateway: TextGateway)
  + send(reminder: Reminder): void
    gateway.sendText(reminder.patient(), reminder.text())
    return

class CancelLineChannel implements ReminderChannel
  - inner: ReminderChannel
  - cancelLine: String
  + new(inner: ReminderChannel, cancelLine: String)
  + send(reminder: Reminder): void
    inner.send(reminder.withFooter(cancelLine))
    return
```

`ReminderChannel` and `Reminder` are the substitutability skill's:
`send` delivers the reminder or hands it on and raises nothing, and
`Reminder` answers `patient()` and `text()`. `CancelLineChannel` keeps
that promise, because it always hands the reminder on. `withFooter` is
the message this skill adds, as the Before explains. The pattern is a
decorator, named here; `CancelLineChannel` keeps the clinic's word for
it. The composition root, outside this fence, wraps each channel once in
a `CancelLineChannel`. Every reminder is sent once, with the line added
once: an unwrapped channel sends the reminder it is given once, and a
wrapped channel adds the line to a copy once and hands that copy to its
inner channel once. Both fences store nothing.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A pattern whose force nobody can point to in the code.
- An interface with one implementation, other than a port to an outside
  system, or a factory with one product.
- An observer with one listener in the same module whose reaction must
  happen at once.
- Class names made only of pattern words, such as
  `AppointmentFactoryImpl` or `ChannelDecorator`, on a class whose job
  is a clinic concept.
- The same check or step copied into every implementation of one
  interface.
- Two patterns answering one force in one module.

## Common mistakes

- Choosing a pattern because a catalogue lists it, before the code shows
  its force.
- Keeping a pattern after its last variant has gone.
- Adding a class hierarchy where a value or a function would do.
- Naming classes after the pattern instead of the clinic's concept.
- Combining several patterns at once to make a module ready for every
  change.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-encapsulating-what-varies](../oo-encapsulating-what-varies/SKILL.md)
  finds the seam from evidence before a pattern is added.
- [oo-replacing-conditionals-with-polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  gives a state or a strategy its own objects.
- [oo-choosing-composition-over-inheritance](../oo-choosing-composition-over-inheritance/SKILL.md)
  chooses holding an object over extending it, which a decorator uses.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  gives a factory or a builder its job.
- [oo-naming-classes-and-methods](../oo-naming-classes-and-methods/SKILL.md)
  keeps a class name on the clinic's concept.

## Further reading

- [Patterns by problem](references/patterns-by-problem.md)
- [Patterns beyond objects](references/patterns-beyond-objects.md)
