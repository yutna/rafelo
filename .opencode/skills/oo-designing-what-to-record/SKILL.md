---
name: oo-designing-what-to-record
description: Use when deciding what to log, measure or trace, when an incident cannot be explained from the records, or staff actions need an audit trail.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing What to Record

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Records outlive the moment that produced them, so they are part of the
design and not an afterthought. This skill decides each record from the
question it must answer and the person who asks it, keeps audit records
with the acts they describe, gives each request one correlation
identifier, and keeps patients' details out of logs, metrics and
traces.

## When to use

- A feature needs log records, metrics or traces and nobody has said
  what each one is for.
- An incident cannot be explained from the records the system kept.
- Staff actions on patients' files need an audit trail.
- An error is logged in several layers as it passes through them.
- A log line, metric or trace carries a patient's name or clinical
  details.
- The clinic asks for a count of outcomes, such as refused bookings.

## When not to use

- The question is which error a method raises, or which caller handles
  it. That is designing failure behaviour.
- The question is the history of an object's own status changes.
  Modeling lifecycles, rule 6, covers it.
- The record is a domain event that other parts react to. That is
  publishing domain events.
- The code is a short script or a test whose output nobody reads after
  it ends.

## Core rules

1. Rule. **Decide each record from the question it must answer and the
   person who asks it.** The person on call asks why one request failed
   and reads a log record. A practice manager asks how many bookings
   were refused today and reads a metric. An auditor asks who recorded
   a patient's allergy and when, and reads an audit record. A record
   that answers no one's question is noise that hides the ones that do.

2. Rule. **Keep an audit record as domain data, written by the
   use-case object in the same transaction as the act it records, and
   kept for as long as the clinic must answer for the act; never a log
   line, which may be sampled, rotated or dropped.** Modeling
   lifecycles, rule 6, keeps the history of an object's own
   transitions; an audit record covers any other act the clinic must
   answer for, such as an allergy recorded in a patient's file. It is
   stored with the act as the outbox is stored with a change, in one
   transaction, as publishing domain events, rule 4, does.

3. Rule. **Give each request one correlation identifier where it enters
   the system, and carry it on every log record, message and event the
   request causes.** One incident can then be followed from its records
   across threads and processes.

4. Default. **Record a failure once, where it is handled: the handler
   at the program's edge that turns a fault into a general failure, as
   designing failure behaviour, rule 2, places it, writes one log
   record with the correlation identifier and the error, and no layer
   logs an error and raises it again.** A failure logged at every layer
   it passes reads as several failures.

   The exception is an adapter that translates an outside system's
   error: it records the original error before it raises the port's
   own, because the original is lost after that.

5. Rule. **Keep patients' personal and clinical details out of logs,
   metrics and traces: record identities, such as a `PatientId`, and
   outcomes, never names, contact details, diagnoses or notes.** Those
   records reach more people and live in more places than the patient's
   file, and nobody checks who reads them the way the file is checked.

6. Default. **Count with metrics: each outcome the clinic watches, such
   as bookings made or refused, is a counter or a measured duration,
   and each metric takes a few label values, such as the site, never a
   patient or appointment identity, which would make one series per
   patient.**

   The exception is a count needed once, for one investigation: query
   the logs or the store for it instead of adding a metric.

7. Rule. **Keep logging out of domain objects: a domain object raises
   its refusals and records its domain events, and the application
   service, the handler at the edge and the adapters write log
   records.** Where a test must check that a record is written, write
   it through a port the domain owns, as inverting dependencies,
   rule 1, asks.

## Pattern

Before, the use-case object `RecordAllergy` stores the allergy and
writes a log line. That line carries the patient's name and the allergy,
a clinical detail; it is the only trace of who recorded the allergy, and
a log may be rotated away.

Before:

```text
class RecordAllergy
  - patients: Patients
  - log: Log
  + new(patients: Patients, log: Log)
  + run(id: PatientId, allergy: Allergy, by: ClinicianId): void
    raises AllergyAlreadyRecorded
    patient := patients.find(id)
    patient.record(allergy)
    patients.save(patient)
    log.write(patient.fullName(), allergy, by)
    return
```

After, `RecordAllergy` stores the same patient and appends an
`AllergyAuditEntry` to the `AuditTrail` it is given, instead of writing
a log line.

After:

```text
value AllergyAuditEntry
  - patient: PatientId
  - allergy: Allergy
  - by: ClinicianId
  - at: DateTime
  + new(patient: PatientId, allergy: Allergy, by: ClinicianId,
      at: DateTime)

interface AuditTrail
  + append(entry: AllergyAuditEntry): void

class RecordAllergy
  - patients: Patients
  - audit: AuditTrail
  - clock: Clock
  + new(patients: Patients, audit: AuditTrail, clock: Clock)
  + run(id: PatientId, allergy: Allergy, by: ClinicianId): void
    raises AllergyAlreadyRecorded
    patient := patients.find(id)
    patient.record(allergy)
    patients.save(patient)
    audit.append(new AllergyAuditEntry(id, allergy, by, clock.now()))
    return
```

`Patient`, its `record` command and the `AllergyAlreadyRecorded` error
are the encapsulating state and behaviour skill's, in its
`guarding-collections.md` reference; `patient.fullName()` is taken to
answer the patient's name. `Patients` is taken to be the patients'
repository, whose `find` answers the stored patient and whose `save`
stores it. `Log.write` is taken to write one log line. `Clock` is the
inverting dependencies skill's port, whose `now()` answers the current
time. The audit entry is an audit record, not a domain event.

The Before's log line has no place in the After: a failure is logged
once at the edge, as rule 4 says, and the audit entry answers the
auditor.

`run` stores the patient with the new allergy under its `PatientId`, in
the clinic's database, in the one transaction `run` opens and ends. The
After also stores one `AllergyAuditEntry` there, in that same
transaction. `patient.record` raises before `save` or `append` runs, so
a refused allergy stores neither the patient nor an entry. Each version
stores the patient once, and the After appends one entry for each
allergy recorded.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A log line that holds a patient's name, contact details or clinical
  notes.
- An error logged at every layer it passes.
- A log message with no identity of the request, appointment or
  patient.
- An audit question answered from the logs.
- A metric labelled with a patient or appointment identity.
- A domain object that writes to a logger.

## Common mistakes

- Logging every step in case it is needed.
- Counting outcomes by searching the logs.
- Writing the audit record after the transaction commits, where a
  failure loses it.
- Starting a new correlation identifier at each process the request
  reaches.
- Keeping logs as long as audit records, or audit records as briefly as
  logs.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-designing-failure-behaviour](../oo-designing-failure-behaviour/SKILL.md)
  places the one handler that records a fault.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) keeps the
  history of an object's own transitions.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  stores a domain event with the change that caused it.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts a port beside the domain for a clock or a store.
- [oo-separating-reads-from-writes](../oo-separating-reads-from-writes/SKILL.md)
  keeps a read from changing what it reads.

## Further reading

- [Logs, metrics and traces](references/logs-metrics-and-traces.md)
- [Audit records](references/audit-records.md)
