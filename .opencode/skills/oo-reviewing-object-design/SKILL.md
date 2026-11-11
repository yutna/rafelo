---
name: oo-reviewing-object-design
description: Use when reviewing a pull request or a design for object-design problems, or when deciding which review findings must block a merge.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Reviewing Object Design

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A review answers one question for the author: which line of this change
breaks which rule, and what must happen before it merges. It reads the
change, not the whole module, and it keeps the size of the task in view.
A comment that names no rule and shows no evidence is a question, not a
finding. This skill turns a change and the pack's rules into a short set
of findings, each with a verdict.

## When to use

- A pull request needs a review for object-design problems.
- A design is ready to read before its code is written.
- A review comment needs the rule behind it, by skill and number.
- An author and a reviewer disagree about whether a finding blocks.
- A review has grown into a long list with no sense of what must change.

## When not to use

- A review has already named an antipattern, and the question is what to
  do about it: [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md)
  decides the response and its order.
- The question is how to design the change rather than how to review it:
  run the index's design loop first, then review the result.
- The change is an answer used once and then thrown away, which the
  index's sizing table skips entirely.
- The comment is about formatting that a tool in the build already
  checks, such as line length: the tool decides it.

## Core rules

1. Rule. **Review a change against what it must keep and against its
   size.** The change names the rule it implements, with one example it
   accepts and one it rejects, as the index's gate asks before
   designing. It falls in one row of the index's sizing table. A change
   to one method in a class that exists is reviewed for its name and
   its contract, not for a new model.

2. Rule. **Report a finding only with the rule it breaks, by skill and
   number, and the lines of the change that break it.** Before writing
   it, read that rule's number, label and statement in the rule's own
   skill, reached from the checklist question that names it; take none
   of them from memory. A red flag alone is a question to the author
   until it has the evidence the index asks for: a measurement, a
   reproducible bug or a failing test.

3. Rule. **Weigh a finding by the label of the rule it breaks.** The
   index defines the three labels under how strictly a rule is meant. A
   broken rule labelled `Rule.` blocks the merge. A broken `Default.`
   blocks unless the change shows that the rule's exception holds. A
   `Judgement.` is discussed, and the author's reasoned choice stands.
   A preference that no rule backs, such as a name the reviewer likes
   better, never blocks.

4. Rule. **Use the diff checklist for a change to existing code, and
   the design checklist for a new module, context or system before its
   code is written.** Each question in them names the rule that
   answers it, and a finding cites that rule, not the checklist.

5. Default. **Ask for the smallest change that keeps the broken rule,
   within the lines the change touches.** Write a finding about code
   the change does not touch as a separate note for later work.

   The exception is a defect the change makes worse, such as a second
   caller added to a method that already breaks a rule: it is a finding
   against this change.

6. Rule. **Review the tests in a change as part of its design.** Each
   rule the change adds has a test named for that rule that goes
   through the object's public messages, as
   [testing object-oriented code](../oo-testing-object-oriented-code/SKILL.md)
   rules 1 and 3 ask. A rule the change adds with no test at all is a
   finding against that skill's rule 2, which writes each test before
   its code.

## Pattern

Before, the change under review adds `attendeeList`, a query that
returns the list the class keeps. `enrol` was there before the change,
so the only line the change adds is `attendeeList`.

Before:

```text
class AntenatalClass
  - attendees: List<PatientId>
  + new()
    attendees := new List<PatientId>()
  + enrol(patient: PatientId): void
    attendees.add(patient)
    return
  + attendeeList(): List<PatientId>
    return attendees
```

After, the change once its one blocking finding is fixed returns a
read-only view. The field, constructor and `enrol` are unchanged.

After:

```text
class AntenatalClass
  - attendees: List<PatientId>
  + new()
    attendees := new List<PatientId>()
  + enrol(patient: PatientId): void
    attendees.add(patient)
    return
  + attendeeList(): ReadOnlyList<PatientId>
    return attendees.readOnlyView()
```

The review has three findings. First, `attendeeList` hands out the list
the class keeps, so a caller can add a patient without `enrol`; that
breaks
[encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
rule 5, labelled `Rule.`, so it blocks, under rules 2 and 3. Second, a
wish to call the method `bookedMothers` has no rule behind it, since
`attendeeList` already names the answer as
[naming classes and methods](../oo-naming-classes-and-methods/SKILL.md)
rule 2 asks, so it does not block, under rule 3. Third, `enrol`
accepting the same patient twice lies in code the change does not
touch, so it becomes a separate note, under rule 5.

`new List<PatientId>()` is taken to mean an empty list the class owns.
Both fences store nothing and leave out how the class is stored. Each
version sets `attendees` in its constructor before `enrol` or
`attendeeList` reads it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A review comment with no rule and no evidence behind it.
- A blocking comment on a choice a `Judgement.` rule leaves open.
- A request to change code the change does not touch.
- A new rule in the change with no test named for it.
- A review of a one-method change that asks for a new model.
- A long list of comments with nothing marked as blocking or not.

## Common mistakes

- Blocking on a name the reviewer would have chosen.
- Letting a broken `Rule.` pass because the change is small.
- Reviewing the whole module instead of the change.
- Reporting red flags as findings with no evidence.
- Asking for a redesign where a one-line fix keeps the rule.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task, defines the rule
  labels, and gives the design loop.
- [oo-recognising-antipatterns](../oo-recognising-antipatterns/SKILL.md)
  names a bad shape and decides what to do about it.
- [oo-testing-object-oriented-code](../oo-testing-object-oriented-code/SKILL.md)
  shapes the tests a change carries.
- [oo-designing-for-testability](../oo-designing-for-testability/SKILL.md)
  moves a value a test cannot repeat behind a port.
- [oo-refactoring-toward-object-design](../oo-refactoring-toward-object-design/SKILL.md)
  restructures code in steps that keep its tests passing.
- [oo-working-with-legacy-code](../oo-working-with-legacy-code/SKILL.md)
  brings old code that no test can build under test first.

## Further reading

- [Diff checklist](references/diff-checklist.md)
- [Design checklist](references/design-checklist.md)
