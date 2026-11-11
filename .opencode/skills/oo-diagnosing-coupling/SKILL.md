---
name: oo-diagnosing-coupling
description: Use when a change ripples through many classes, a part is hard to change or test alone, or you need to judge how tightly two parts are tied.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Diagnosing Coupling

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Coupling is the cost of a change spreading: two parts are tied when a
change to one forces a change to the other. This skill names the tie,
weighs how strong and how widespread it is, and uses the change history
to decide which tie to loosen first. It treats ladders and metrics as
places to look, not as scores to chase.

## When to use

- A change to one behaviour keeps editing several classes or modules.
- A part is hard to change or test without bringing its neighbours.
- A review asks how tightly two classes or modules are tied.
- A refactor needs an order: which tie to loosen first.
- A module boundary needs a stability check.

## When not to use

- The question is where one new behaviour belongs, not how two existing
  parts are tied. That is assigning responsibilities.
- The change is a one-line fix or a throwaway script. Fix it and stop.
- There is no code yet to measure. A new design starts from sizing in
  the index.

## Core rules

1. Rule. **Name the tie before judging it: connascence is what must
   change together.** Two parts share connascence when a change to one
   forces a change to the other. Naming the agreement, instead of
   calling the pair "tightly coupled", gives the next rule something to
   order.

2. Rule. **Look for the static kinds in the code: name, type, meaning,
   position, algorithm.** Name is a method or field both sides spell.
   Type is a type both sides accept. Meaning is a convention both sides
   read into a value, such as a magic number. Position is the order of
   arguments. Algorithm is a step both sides repeat and must keep in
   step.

3. Rule. **Then look for the dynamic kinds, which show only at run
   time: execution order, timing, value, identity.** Execution order is
   a sequence calls must follow. Timing is a moment they must meet.
   Value is a set of values that must agree. Identity is the same
   object, not a copy. The nine kinds run name, type, meaning, position,
   algorithm, execution order, timing, value, identity; each dynamic
   kind is stronger than any static one.

4. Rule. **Weigh a tie by strength, locality and degree.** Strength
   follows the kind: later kinds in the order are stronger, and dynamic
   beats static. Locality asks where the tie sits; the same kind costs
   less inside one class than across modules. Degree counts how many
   elements share it. A strong tie in one method can be cheaper than a
   weak tie repeated in twelve classes.

5. Default. **Refactor toward the weaker, more local, lower-degree
   tie.** Position becomes name through a parameter object or named
   fields. Meaning becomes type through a value type or an enum instead
   of a magic value. A duplicated algorithm gets one owner and the
   other copies delegate.

   The exception is a tie set by an outside format or protocol. Wrap
   that tie at the boundary and keep it out of the domain model.

6. Judgement. **Loosen the strongest tie that the most modules share
   first.** Strength, degree and locality decide together. The first
   candidate is the strongest tie shared most widely across modules; a
   weaker tie inside one class can wait.

7. Rule. **Label a module tie on the coupling ladder, tightest first:
   content, common, external, control, stamp, data.** Content reaches
   into another module's internals. Common shares global data. External
   follows a fixed outside format or protocol. Control passes a flag
   that steers the callee. Stamp passes a whole structure where a part
   is needed. Data passes only the values needed. Use the rungs as
   diagnostic labels, not as a score.

8. Rule. **Label what holds a class together on the cohesion ladder,
   weakest first: coincidental, logical, temporal, procedural,
   communicational, sequential, functional.** Coincidental has no
   theme. Logical groups by kind of thing. Temporal groups by when it
   runs. Procedural groups by a shared sequence. Communicational works
   on the same data. Sequential feeds one part's output to the next.
   Functional has every part serving one task. A class held together
   only by kind or by timing is a candidate to split.

9. Rule. **Read package dependency counts as afferent, efferent and
   instability.** Afferent counts how many modules depend on this one.
   Efferent counts how many it depends on. Instability is
   `efferent / (afferent + efferent)`, from 0 for stable to 1 for
   unstable. Treat the counts as places to look, not as targets.

10. Default. **Depend in the direction of stability.** A module many
    others depend on should not depend on volatile details. Point each
    dependency from the less stable module toward the more stable one.

    The exception is a boundary adapter whose job is to meet a volatile
    outside system. Keep it at the edge and keep the stable core clear
    of it.

11. Rule. **Measure before judging.** Evidence is what changes together
    in the version history, the size of the change a typical request
    causes, and dependency counts. A coupling smell becomes a finding
    only with such evidence; without it, the red flags below are places
    to look.

## Pattern

Before, `BillingDesk` calls `InvoiceBuilder.build(visit, "AXA", 2, true)`.
`"AXA"` is an insurer code that billing and claims must spell the same
way, `2` is the plan tier, and `true` means lab fees are included. The
call carries connascence of meaning, because the bare code and tier are
conventions, and connascence of position, because the caller must
remember which slot is which. The flag also steers the builder's logic,
which is control coupling.

Before:

```text
class BillingDesk
  - invoices: InvoiceBuilder
  + new(invoices: InvoiceBuilder)
  + invoice(visit: Visit): Invoice
    return invoices.build(visit, "AXA", 2, true)

class InvoiceBuilder
  + build(visit: Visit, insurer: String, tier: Int, labFees: Boolean): Invoice
    return new Invoice(visit, insurer, tier, labFees)
```

After, `InvoiceBuilder.build(visit, coverage)` takes one `Coverage`.
The insurer code is an `InsurerCode`, the tier is a `PlanTier`, and the
lab-fee choice is a `LabFees`. The three parts are named, so a caller
cannot put the tier where the insurer belongs, and the flag no longer
reaches the builder as a bare switch.

After:

```text
value InsurerCode
  - code: String
  + new(code: String)

enum PlanTier
  Basic
  Family

enum LabFees
  Excluded
  Included

value Coverage
  - insurer: InsurerCode
  - tier: PlanTier
  - labFees: LabFees
  + new(insurer: InsurerCode, tier: PlanTier, labFees: LabFees)

class BillingDesk
  - invoices: InvoiceBuilder
  + new(invoices: InvoiceBuilder)
  + invoice(visit: Visit, coverage: Coverage): Invoice
    return invoices.build(visit, coverage)

class InvoiceBuilder
  + build(visit: Visit, coverage: Coverage): Invoice
    return new Invoice(visit, coverage)
```

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A request that keeps touching the same set of files across different
  modules.
- A boolean or mode parameter that switches the callee's behaviour.
- A parameter list of several values of the same type whose order
  matters.
- A magic value that two modules must spell the same way.
- Two classes whose version history shows changes in the same commits.
- A module many others depend on that depends on a volatile detail.

## Common mistakes

- Treating a metric as a target and refactoring until the number moves.
- Trying to remove all coupling. Parts that work together must know
  something about each other; the goal is a weaker, more local tie.
- Counting imports and missing connascence of meaning, timing or
  algorithm that no import shows.
- Splitting a cohesive class only because it is long.
- Reading high instability as a defect. A leaf module with no dependants
  is meant to be unstable.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes the task and defines the
  rule labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  decides where a new behaviour goes when the question is ownership,
  not coupling.

## Further reading

- [Connascence](references/connascence.md)
- [Coupling and cohesion ladders](references/coupling-and-cohesion-ladders.md)
