---
name: oo-bounding-contexts
description: Use when splitting a large model between teams, choosing how parts with their own models talk, or deciding which parts to build or buy.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Bounding Contexts

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A clinic's system grows past one model that one team can hold. Reception
and billing begin with different meanings for an appointment, another
part fills prescriptions, and payroll arrives as a product nobody in
the clinic wants to build. This skill draws the line between parts that
keep a model of their own, says how those parts talk and who must be
asked before a change, places a translator where a part depends on a
model it does not control, and keeps design effort on the work that
makes this clinic different.

## When to use

- A model has grown past one team, and a change to it needs several
  teams to agree.
- One word has a different meaning for two separately owned parts of the
  system.
- Two parts with their own models must talk, and nobody can say which
  one depends on the other.
- A part depends on a model that another team or an outside service
  controls.
- The team is deciding which parts to model richly, which to keep plain
  and which to buy.
- A new product or service must fit beside the clinic's model without
  replacing it.

## When not to use

- One team owns the whole code and every word has one meaning there:
  there is one model, and no boundary to draw.
- Two meanings of one word share one codebase and one team: they get two
  classes, as rule 4 of speaking the domain language asks.
- The question is which layer or class depends on which inside one
  context.
- The question is the shape or the version of data that crosses a
  boundary already drawn, such as an API's fields.

## Core rules

1. Rule. **Draw a context boundary where the model's words change
   meaning.** A context is a part of the system whose model has its own
   words and one owner. Inside one context each word means one thing; at
   the line, reception's *appointment* is a booked slot while billing's
   *billable visit* is the visit it prices. Where those two meanings
   meet, two contexts meet. Each context keeps its own model, even when
   both read one table today. Inside shared code, two meanings become
   two classes, as rule 4 of speaking the domain language asks; its
   [signs of two owners][two-meanings] tell that case apart from this
   one. This skill decides where whole models part.

2. Rule. **Give each context one owning team, its own model and the data
   it changes.** Another context never reads that context's tables or
   uses its domain classes. It asks through an interface the owning
   context publishes, or reacts to an event the owning context
   publishes, as
   [publishing domain events](../oo-publishing-domain-events/SKILL.md)
   describes. A table that two contexts write turns every change to that
   table into a negotiation between two teams.

3. Rule. **Write down the context map: for every pair of contexts that
   talk, which one depends on the other, and how they agree.** The
   depending context takes the other's model as it is (conformist),
   translates it at its own edge (anti-corruption layer), or shares a
   small model both teams own and change together (shared kernel); or
   the depended-on context publishes one stable interface and language
   for every consumer (open host with a published language). A pair that
   need not talk chooses separate ways. The map is where a new team
   member learns who must be asked before a change.

4. Default. **Where a context depends on a model it does not control,
   put an anti-corruption layer in the depending context.** One
   translator at that context's edge turns the other model's terms into
   its own, so no class beyond the translator names the other model. The
   translator is an adapter of the kind rule 1 of
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   describes, and it keeps no business decision of its own; it only
   translates.

   The exception is a model the context is content to adopt, such as a
   code set every clinic must use. Take its words as they are, and record
   that choice on the map.

5. Judgement. **Sort the clinic's work into core, supporting and
   generic.** The core is where this clinic differs from others, such as
   how it fits urgent patients into clinicians' days; it gets the
   richest model and the strongest people. A supporting part, such as
   reserving meeting rooms, gets a plain model or scripts. A generic part,
   such as payroll or sending mail, is bought or used as a service. What
   tips the balance is whether doing the part better than others matters
   to the clinic's patients or its business.

6. Judgement. **Keep the core model to what makes the clinic
   different.** Write the core down in a short statement the team agrees
   on, and move generic parts out of the core context into their own, so
   the core stays small enough to read. Start with fewer, larger
   contexts, and split one when a word's meaning splits inside it or two
   teams keep blocking each other's changes. What tips the balance is
   the cost of the translation a new boundary adds against the cost of
   the coordination it removes.

## Pattern

Before, billing's `BillableVisit` holds `Appointment`, scheduling's own
class. The fence names `Appointment` only as a type; its declaration
stays in scheduling's model, outside this example. Billing names
scheduling's model, so each change to `Appointment` reaches billing, and
billing could send it `cancel`.

Before:

```text
class BillableVisit
  - appointment: Appointment
  - invoiceNumber: String?
  + new(appointment: Appointment)
    invoiceNumber := null
  + bill(number: String): void
    raises VisitAlreadyBilled
    if invoiceNumber = null then
      invoiceNumber := number
    else
      raise VisitAlreadyBilled
    return
  + invoice(): String?
    return invoiceNumber
```

The rest of `BillableVisit` is the domain-language reference's class;
only the type of `appointment` and of its constructor parameter differ.

After, `BillableVisit` is the domain-language reference's class exactly.
Scheduling publishes `AppointmentCompleted` after `Appointment.complete`
commits. Billing's anti-corruption layer is `SchedulingTranslator`: its
`handle` creates one billable visit from the appointment's identity and
stores it through `BillableVisits.add`, billing's own port. `DomainEvent`
and the handler form `handle(id, event)` are the publishing domain events
skill's; the `EventId` is the one its outbox gave the event.

After:

```text
interface DomainEvent

value AppointmentCompleted implements DomainEvent
  - appointment: AppointmentId
  + new(appointment: AppointmentId)
  + appointment(): AppointmentId
    return appointment

class BillableVisit
  - appointment: AppointmentId
  - invoiceNumber: String?
  + new(appointment: AppointmentId)
    invoiceNumber := null
  + bill(number: String): void
    raises VisitAlreadyBilled
    if invoiceNumber = null then
      invoiceNumber := number
    else
      raise VisitAlreadyBilled
    return
  + invoice(): String?
    return invoiceNumber

interface BillableVisits
  + add(visit: BillableVisit): void

class SchedulingTranslator
  - billableVisits: BillableVisits
  + new(billableVisits: BillableVisits)
  + handle(id: EventId, event: AppointmentCompleted): void
    billableVisits.add(new BillableVisit(event.appointment()))
    return
```

What is stored is one new billable visit, under the appointment's
identity, in billing's own store, in a transaction of its own after
scheduling's change commits; scheduling's data is not touched. The
appointment's identity is the one thing the two contexts share,
published by scheduling for others to hold. The translator's check that
it has not handled the event before (publishing domain events, rule 5)
is left out of the fence.

`SchedulingTranslator.handle` creates and stores one billable visit, and
no billing class in the After names the `Appointment` class: the
identifier is all billing holds. Every field is set in a constructor
named for it before a query or `handle` reads it, and no step runs twice.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- Two teams that must agree on every change to one shared class or
  table.
- A class in one context that imports another context's domain classes
  outside its translator.
- A word whose meaning changes from one module to the next with no
  translation between them.
- A translator at a boundary that holds business decisions.
- The strongest developers working on a generic part, such as sending
  mail, while the core waits.
- No written record of which context depends on which.

## Common mistakes

- Drawing one context per aggregate or per screen.
- Sharing one model across contexts to avoid writing a translator.
- Letting a bought product's model become the core's model.
- Splitting contexts by technical layer instead of by meaning.
- Translating at the boundary in both contexts, so neither owns the
  translation.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-speaking-the-domain-language](../oo-speaking-the-domain-language/SKILL.md)
  gives two meanings of one word two classes inside shared code.
- [oo-naming-classes-and-methods](../oo-naming-classes-and-methods/SKILL.md)
  keeps one word for one concept inside one model.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  publishes the event a neighbouring context reacts to.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts the translator behind a port at the depending context's edge.

## Further reading

- [Context maps](references/context-maps.md)
- [Core and generic parts](references/core-and-generic-parts.md)

[two-meanings]: ../oo-speaking-the-domain-language/references/two-meanings-of-one-word.md#signs-of-two-owners
