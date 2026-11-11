---
name: oo-recognising-antipatterns
description: Use when a review names an antipattern such as a god class, lava flow or poltergeist, or when sorting code smells into the rules they break.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Recognising Antipatterns

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A review often comes back with a list of smells: a class that does too
much, code nobody dares delete, an object every test must reset. A
smell is a place to look, not a verdict; the evidence in the code or its
history decides whether it is an antipattern. This skill names each
antipattern from that evidence, sends it to the rule it breaks in the
skill that owns that rule, and fixes the one whose code changes most
first, one at a time behind passing tests.

## When to use

- A review names an antipattern, such as a god class, lava flow or
  poltergeist, and asks what to do about it.
- A list of code smells must be sorted into the rules each one breaks.
- A team cannot agree which of several smells to fix first.
- A module is hard to change and nobody has said which rule it breaks.
- Code nobody understands is kept in the module and nobody knows whether
  it can go.

## When not to use

- The antipattern is already named and the question is how to fix it:
  the skill that owns the broken rule answers, such as assigning
  responsibilities for a class that does too much.
- A smell has no evidence behind it yet, such as a long class that
  nobody changes: leave it and look again when a change reaches it.
- The question is the steps of a safe refactoring: that is
  [refactoring toward object design](../oo-refactoring-toward-object-design/SKILL.md).
- The question is whether one pattern pays its way: that is choosing a
  pattern.

## Core rules

1. Rule. **Name an antipattern only with evidence from the code or its
   history.** A class that most change requests touch, a single instance
   that every test must reset, or code that no run has reached in a year
   is evidence. A smell is a place to look, as every red flag in this
   pack is; the evidence makes it a finding.

2. Rule. **Treat an antipattern by the rule it breaks, in the skill that
   owns that rule, rather than by a fix of its own.** A god class goes to
   assigning responsibilities, rules 7 and 8; an anemic model to deciding
   object or data, rule 1; a service locator to inverting dependencies,
   rule 5; a single instance reached from anywhere to inverting
   dependencies, rules 2 and 3; a dependency cycle to organising modules,
   rule 4; a pattern with no force to choosing a pattern, rules 2 and 6;
   shotgun surgery to diagnosing coupling, rule 1, and then hiding
   implementation, rule 5; a class that only forwards to limiting what an
   object knows, rule 3.

3. Rule. **Remove lava flow once evidence shows it does not run.** Lava
   flow is code that nobody understands, nobody calls on purpose and
   nobody dares delete. Delete it, since version control keeps it. Where
   it does run, cover what it does with a test before changing it. Code
   kept in case it is needed is read by every newcomer and changed in
   every refactoring.

4. Default. **Inline a poltergeist: a short-lived class with no state of
   its own that is created only to start another object's work and then
   dropped.** The caller sends that message itself.

   The exception is the use-case object that a user interface or an API
   calls first, which assigning responsibilities, rule 5, asks for even
   when it only delegates.

5. Judgement. **Fix first the antipattern in the code that changes most
   often and costs most to change, and leave alone a stable one that no
   change needs.** What tips the balance is the change history: a god
   class that no request touches costs nothing until one does.

6. Rule. **Change one antipattern at a time, in steps that each leave the
   tests passing.** The steps of a safe refactoring are in
   [refactoring toward object design](../oo-refactoring-toward-object-design/SKILL.md).

## Pattern

Before, `CloseVisit` creates an `InvoiceStarter` for one message.
`InvoiceStarter` holds no state of its own, lives for one message and is
dropped: a poltergeist. After, `CloseVisit` sends its invoicing port the
message itself, and `InvoiceStarter` is gone.

Before:

```text
class InvoiceStarter
  - invoicing: Invoicing
  + new(invoicing: Invoicing)
  + start(visit: VisitId): void
    invoicing.issueFor(visit)
    return

class CloseVisit
  - invoicing: Invoicing
  + new(invoicing: Invoicing)
  + run(visit: VisitId): void
    starter := new InvoiceStarter(invoicing)
    starter.start(visit)
    return
```

After:

```text
class CloseVisit
  - invoicing: Invoicing
  + new(invoicing: Invoicing)
  + run(visit: VisitId): void
    invoicing.issueFor(visit)
    return
```

`Invoicing` is taken to be a port whose `issueFor` issues one invoice for
the visit and raises nothing in this fence. `VisitId` is the visit's
identity. What `issueFor` stores, under which identity, where it stores
it and in which transaction are left out of both fences, as is closing
the visit itself. Each version issues one invoice for each `run`: the
Before sends `start` once, which sends `issueFor` once, and the After
sends `issueFor` once.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A class that most change requests touch.
- An object that looks up its collaborators in a global registry.
- A single instance reached from anywhere and reset in test setup.
- Code that no run reaches and no test covers.
- A class created only to send one message and then dropped.
- One business change that edits many modules.

## Common mistakes

- Calling code an antipattern from its size alone.
- Rewriting a stable antipattern that no change needs.
- Fixing several antipatterns in one change.
- Deleting code because nobody remembers it, with no evidence that it
  does not run.
- Replacing a single global instance with a service locator.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  splits a god class and gives a use-case object its job.
- [oo-deciding-object-or-data](../oo-deciding-object-or-data/SKILL.md)
  decides whether an anemic model has a rule with no home.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  keeps a service locator and a single global instance out of domain
  code.
- [oo-organising-modules](../oo-organising-modules/SKILL.md) breaks a
  dependency cycle between modules.
- [oo-choosing-a-pattern](../oo-choosing-a-pattern/SKILL.md) asks whether
  a pattern still has a force.
- [oo-diagnosing-coupling](../oo-diagnosing-coupling/SKILL.md) names the
  tie behind shotgun surgery.
- [oo-hiding-implementation](../oo-hiding-implementation/SKILL.md) keeps
  one decision in one module once the tie is named.
- [oo-limiting-what-an-object-knows](../oo-limiting-what-an-object-knows/SKILL.md)
  removes a middle man that only forwards.
- [oo-refactoring-toward-object-design](../oo-refactoring-toward-object-design/SKILL.md)
  takes each change in small steps that keep the tests passing.

## Further reading

- [Antipatterns and their rules](references/antipatterns-and-their-rules.md)
- [Gathering evidence](references/gathering-evidence.md)
