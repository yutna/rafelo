---
name: oo-layering-the-system
description: Use when choosing layered, hexagonal or clean architecture, when an inner layer imports an outer one, or a screen needs its framework in tests.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Layering the System

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A layered system keeps its business rules at the centre and its outside
systems at the edge. The rule that produces the shape is simple: source
dependencies point inward, and an inner layer never names an outer one.
This skill draws that rule, gives each layer one job, keeps the hard
edges humble, sizes the number of layers to the ways in and out, and
lets a plain read skip the domain while every change goes through a use
case.

## When to use

- You are choosing layered, hexagonal, onion or clean architecture.
- A domain or application class imports a web, screen or storage type.
- A screen, job or message listener needs its framework running before
  a test can check it.
- A second way in, such as an import, copies a use case instead of
  calling it.
- You are deciding how many layers a system with several ways in and
  out needs.
- A read and a change both go through the domain, although the read
  decides nothing.

## When not to use

- The question is how one class gets its collaborators, such as a
  constructor parameter or a port for a clock: that is
  [inverting dependencies](../oo-inverting-dependencies/SKILL.md).
- The question is which domain object, domain service or use case holds
  a rule: that is
  [placing domain logic](../oo-placing-domain-logic/SKILL.md).
- The code is a script or a one-off tool with one way in and no
  business rules to protect. Keep it a script.
- The question is how modules group by business area or depend on each
  other. That is a question of module boundaries, not of the direction
  between layers inside one module.

## Core rules

1. Rule. **Point every source dependency inward, toward the domain.**
   The domain depends on nothing outside itself. The application layer,
   one object per use case, depends on the domain. The adapters for
   screens, web requests, jobs, stores and outside services depend on
   both, and the composition root depends on all of them. Where control
   must flow outward, such as a use case storing an appointment, the
   inner layer declares a port and an outer adapter implements it, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rules 1 and 3 ask. Layered, hexagonal, onion and clean architectures
   are drawings of this one rule.

2. Rule. **Keep each layer to its job.** The domain holds the business
   rules. The application layer loads, delegates, stores and sets the
   transaction, as
   [placing domain logic](../oo-placing-domain-logic/SKILL.md) rule 2
   asks. An adapter turns outside input into a call on a use case and
   the reply into outside output. A business condition found in an
   adapter moves inward, as
   [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md)
   rule 5 asks of an interface.

3. Rule. **Cross an inner boundary only with the inner layer's types.**
   An adapter turns the framework's request into the values a use case
   takes, and the use case answers with its own values or raises its own
   errors. No framework request, storage row or framework marker reaches
   the application or the domain. A request that arrives as a transfer
   object is converted once at the edge, as
   [deciding object or data](../oo-deciding-object-or-data/SKILL.md)
   rule 3 asks.

4. Default. **Make each edge that is hard to test a humble object.** A
   screen, a scheduled job or a message listener keeps only the code
   that needs its framework, such as reading the input and writing the
   output, and sends everything else to an object that can be tested
   without the framework.

   The exception is an edge with nothing to decide, such as a health
   check that always gives the same answer: it needs no split.

5. Judgement. **Choose how many layers by how many ways in and out the
   system has.** A small service with one entry point and one store may
   keep its use cases and adapters close around the domain, while a
   system booked from a web page, a nightly import and another team's
   service earns the full set, so every entry point calls the same use
   cases. What tips the balance is the number of entry points and
   outside systems, and whether the business rules must be tested
   without them.

6. Judgement. **Let a read that applies no business rule skip the domain
   and go through a read query that returns plain data.** Today's
   appointments listed for a screen are such a read, while every change
   goes through a use case and the domain. What tips the balance is
   whether the read decides anything: a read that decides who may see
   what is a use case. The read query is
   [designing repositories](../oo-designing-repositories/SKILL.md)
   rule 6.

## Pattern

`FrameworkController`, `FrameworkRequest`, `FrameworkReply` and the
reference's `FrameworkJob` and `JobRun` stand for any framework's own
types; this skill names no framework.

Before, `WaitingListController` owns the use case. It reads the request,
loads the list, joins the patient and saves the list, so the use case
lives in a class that needs the web framework and the database to run,
and a nightly import that also adds patients to waiting lists cannot
reach it.

Before:

```text
-- adapters
class WaitingListController extends FrameworkController
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + post(request: FrameworkRequest): FrameworkReply
    clinician := clinicianIn(request)
    list := database.waitingListFor(clinician)
    list.join(patientIn(request))
    database.saveWaitingList(clinician, list)
    return FrameworkReply.ok()
  - clinicianIn(request: FrameworkRequest): ClinicianId
  - patientIn(request: FrameworkRequest): PatientId
```

After, the domain holds the list and its rule, the application layer
holds `JoinWaitingList`, and the adapters translate the request and the
store. `clinicianIn` and `patientIn` read the form's text into the
values and refuse text that cannot be read. `waitingListFor` is taken to
answer the waiting list stored under a clinician, and `saveWaitingList`
is taken to store it there once. `WaitingLists.save` takes the clinician
because a `WaitingList` holds no identity of its own. The clinic keeps
one waiting list per clinician, so the list is stored under its
clinician's identity, in the clinic's database, in the transaction `run`
opens. `AlreadyWaiting` from `join` passes on to the framework, which
turns it into a reply. `FrameworkReply.ok()` is taken to answer a reply
that reports success. The controller still extends the framework's
controller base class, because the framework calls `post`; the business
step now sits in the application layer. Both versions send `join` once
and store the list once: the before version through
`database.saveWaitingList`, the after version through `waitingLists.save`.
Every field type in the after version belongs to its own layer or an
inner one: `WaitingLists` and `WaitingList` are domain types,
`JoinWaitingList` is an application type, and `ClinicDatabase` is the
type the inverting skill gives the store, held only by the adapter.

After:

```text
-- domain
class WaitingList
  - patients: List<PatientId>
  + new()
    patients := new List<PatientId>()
  + join(patient: PatientId): void
    raises AlreadyWaiting
    if patients.contains(patient) then
      raise AlreadyWaiting
    else
      patients.add(patient)
    return
  + waiting(): ReadOnlyList<PatientId>
    return patients.readOnlyView()

interface WaitingLists
  + forClinician(clinician: ClinicianId): WaitingList
  + save(clinician: ClinicianId, list: WaitingList): void

-- application
class JoinWaitingList
  - waitingLists: WaitingLists
  + new(waitingLists: WaitingLists)
  + run(clinician: ClinicianId, patient: PatientId): void
    list := waitingLists.forClinician(clinician)
    list.join(patient)
    waitingLists.save(clinician, list)
    return

-- adapters
class WaitingListController extends FrameworkController
  - joinWaitingList: JoinWaitingList
  + new(joinWaitingList: JoinWaitingList)
  + post(request: FrameworkRequest): FrameworkReply
    joinWaitingList.run(clinicianIn(request), patientIn(request))
    return FrameworkReply.ok()
  - clinicianIn(request: FrameworkRequest): ClinicianId
  - patientIn(request: FrameworkRequest): PatientId

class DatabaseWaitingLists implements WaitingLists
  - database: ClinicDatabase
  + new(database: ClinicDatabase)
  + forClinician(clinician: ClinicianId): WaitingList
    return database.waitingListFor(clinician)
  + save(clinician: ClinicianId, list: WaitingList): void
    database.saveWaitingList(clinician, list)
    return
```

`WaitingList` keeps the shape the composition skill gives it. The
`-- domain`, `-- application` and `-- adapters` comments mark the three
layers. `DatabaseWaitingLists.forClinician` sends `waitingListFor` once
and `save` sends `saveWaitingList` once.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A domain or application class that imports a web, user-interface or
  storage framework type.
- A domain class that extends a framework's base class or carries its
  markers.
- A second way in, such as an import or a job, that reaches a use case
  by faking a web request.
- Tests of business rules that start a server or a database.
- A use case that takes or returns a framework's request, response or
  row type.
- A store's interface declared beside its database adapter rather than
  beside the domain.

## Common mistakes

- Adding a layer for each technical kind, such as controllers, services,
  managers and helpers, each calling the next whatever the change.
- Routing every read through the domain model even when no rule applies.
- Treating hexagonal, onion and clean as rival designs to choose
  between rather than one rule drawn three ways.
- Putting decisions in the composition root or in framework
  configuration.
- Testing a humble edge in depth while the object it calls goes
  untested.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts a port beside the domain, an adapter at the edge and the
  composition root at the program's start.
- [oo-placing-domain-logic](../oo-placing-domain-logic/SKILL.md) keeps
  the use-case object to loading, delegating, storing and the
  transaction.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  chooses the use-case object and the domain object that owns a rule.
- [oo-designing-repositories](../oo-designing-repositories/SKILL.md)
  gives the application layer its ports and its read queries.
- [oo-separating-presentation-from-domain](../oo-separating-presentation-from-domain/SKILL.md)
  keeps a screen humble with a presentation object.

## Further reading

- [One rule, four drawings](references/one-rule-four-drawings.md)
- [Humble edges](references/humble-edges.md)
