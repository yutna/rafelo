---
name: oo-placing-domain-logic
description: Use when choosing a domain service, entity method or application service, when use cases repeat one check, or picking scripts or a domain model.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Placing Domain Logic

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A module's business rules can live in a few scripts, in objects that hold
their data, or in a service set beside them. The choice changes what a
second rule costs: a script grows another copy of a check, while an
object or a service has one place to change. This skill chooses the
style, keeps the use-case object to loading, delegating and storing, and
moves a rule that no single aggregate can decide to a domain service that
holds no state. The aim is one home for each rule, reachable from every
request that needs it.

## When to use

- A controller or a use-case object holds a check on a status, a limit
  or a date.
- Two entry points need the same check, and each has its own copy.
- A rule needs several aggregates, or an answer from outside, and no
  single aggregate can decide it.
- A module mixes scripts that write fields with objects that keep their
  own rules.
- A team is choosing between a transaction script, a domain model and a
  table module for one module.
- A review asks whether a class is an application service, a domain
  service or an entity method.

## When not to use

- The question is which of two domain objects owns one behaviour, and no
  service or layer is involved. That is
  [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md).
- The module has no business rule at all and only moves data between a
  screen and a store, such as an admin form over a lookup table. Keep the
  data path plain.
- The question is how a value checks its own format: that is
  [constructing valid objects](../oo-constructing-valid-objects/SKILL.md).

## Core rules

1. Judgement. **Choose how a module organises its business logic by how
   much its rules interact.** A transaction script, one procedure per
   request, suits a few independent rules, such as recording a patient's
   preferred language. A domain model, objects that hold both data and
   rules, suits rules that interact and grow, such as booking. A table
   module, one class per table that acts on all its rows, suits tooling
   built around sets of records. What tips the balance is whether the
   same rule is needed by more than one request, and whether rules
   depend on one another.

2. Rule. **Keep an application service, the object one use case runs in,
   to coordination: it loads aggregates through repositories, sends them
   commands, stores them, opens and ends the transaction, and turns the
   result into a reply. A business condition found in it moves into the
   domain.** This is the use-case object of
   [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md),
   rule 5, with the loading, the storing and the transaction named.

3. Rule. **Give an operation that no single aggregate can decide, because
   it needs several aggregates or an answer from outside, to a domain
   service: an object in the domain that keeps no state between calls,
   named for the clinic activity it performs, such as `VisitPricing`,
   that takes the aggregates and values it needs as parameters and
   returns a decision or a value. It never loads or stores aggregates;
   the application service does.** Reach for it only after
   [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md),
   rule 4, finds no domain object that can hold the rule. A domain
   service that needs an answer from outside receives that port through
   its constructor, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rule 2 asks; one that needs none holds no field.

4. Default. **Keep one style of business logic in one module: a module
   with a domain model does not also grow transaction scripts that write
   its objects' fields directly.** The exception is a module moving from
   scripts to a model one use case at a time. During the move each use
   case is wholly in one style, and the scripts still to move are listed
   where the team tracks the work.

5. Rule. **Check that a request is well formed at the edge, and decide
   whether it is allowed in the domain: the controller or the application
   service turns text into values and refuses what cannot be read, such
   as a date that does not parse, while whether this patient may book
   this slot is decided by the domain objects.** A value's own format is
   checked once, by the value's constructor, as rule 3 of
   [constructing valid objects](../oo-constructing-valid-objects/SKILL.md)
   asks; the edge only turns that failure into a reply.

## Pattern

Before, the application service `QuoteVisit` holds two ports and decides
the price itself. It loads the rates for the clinician and the patient's
coverage, then chooses which amount to answer. After, `VisitPricing`
holds no field and makes that decision, and `QuoteVisit` only loads the
two values and delegates to it.

Before:

```text
interface RateBook
  + ratesOf(clinician: ClinicianId): Rates

interface Covers
  + coverageOf(patient: PatientId): Coverage

class QuoteVisit
  - rateBook: RateBook
  - covers: Covers
  + new(rateBook: RateBook, covers: Covers)
  + run(kind: AppointmentKind, length: Duration,
      clinician: ClinicianId, patient: PatientId): Fee
    rates := rateBook.ratesOf(clinician)
    coverage := covers.coverageOf(patient)
    fee := rates.feeFor(kind, length)
    if coverage.includes(kind) then
      return coverage.patientShareOf(fee)
    else
      return fee
```

After:

```text
interface RateBook
  + ratesOf(clinician: ClinicianId): Rates

interface Covers
  + coverageOf(patient: PatientId): Coverage

class QuoteVisit
  - rateBook: RateBook
  - covers: Covers
  - pricing: VisitPricing
  + new(rateBook: RateBook, covers: Covers, pricing: VisitPricing)
  + run(kind: AppointmentKind, length: Duration,
      clinician: ClinicianId, patient: PatientId): Fee
    rates := rateBook.ratesOf(clinician)
    coverage := covers.coverageOf(patient)
    return pricing.quote(kind, length, rates, coverage)

class VisitPricing
  + quote(kind: AppointmentKind, length: Duration,
      rates: Rates, coverage: Coverage): Fee
    fee := rates.feeFor(kind, length)
    if coverage.includes(kind) then
      return coverage.patientShareOf(fee)
    else
      return fee
```

`RateBook.ratesOf(clinician)` is taken to answer the rates that apply to
that clinician, and `Covers.coverageOf(patient)` is taken to answer the
coverage that patient holds. They are the two ports, and an adapter at
the edge answers each. `Coverage.includes(kind)` is taken to mean that
the coverage covers that kind of appointment, and
`Coverage.patientShareOf(fee)` is taken to mean the part of that fee the
patient pays under the coverage.

`Rates` keeps the shape
[limiting what an object knows](../oo-limiting-what-an-object-knows/SKILL.md)
gives it, with `feeFor(kind, length)`, and `Coverage` keeps the shape
[diagnosing coupling](../oo-diagnosing-coupling/SKILL.md) gives it, with
its insurer, tier and lab-fee fields; both are used here as types.
`AppointmentKind`, `Duration`, `ClinicianId`, `PatientId` and `Fee` are
types only.

In both versions `run` sends `rateBook.ratesOf` once and
`covers.coverageOf` once; the after version also sends `pricing.quote`
once, and `quote` sends `rates.feeFor` once. The constructor sets every
field before `run` reads one, and no message runs twice. Neither fence
changes or stores an aggregate, so neither opens a transaction; a use
case that stores opens and ends one around its ports, as rule 2 asks.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A business condition, such as a check on a status, a limit or a date,
  in a controller or an application service.
- The same check copied into two use cases or two entry points.
- A domain service that loads or stores aggregates.
- A domain service that reads one aggregate's data and decides for it.
- A module where some use cases change objects through their methods and
  others write the objects' fields directly.

## Common mistakes

- Creating a service for each rule before asking which object holds its
  data.
- Opening the transaction inside a domain object or a repository.
- Naming a service for a layer or a pattern rather than for the activity.
- Building a domain model for a module of a few independent rules.
- Checking business rules at the edge because the form already holds the
  data.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  chooses the use-case object and the domain object that owns a rule.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) draws
  the boundary that one transaction keeps consistent.
- [oo-designing-repositories](../oo-designing-repositories/SKILL.md)
  gives the application service its ports and keeps a change whole.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts each port and the composition root at the edge.

## Further reading

- [Three ways to organise](references/three-ways-to-organise.md)
- [Services by layer](references/services-by-layer.md)
