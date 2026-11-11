---
name: oo-making-work-reliable
description: Use when calls to another system hang, time out or fail midway, when a retry could do the work twice, or a process spans steps that may fail.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Making Work Reliable

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Work that leaves the clinic can hang, answer late, or fail after it has
partly happened. This skill bounds each call to another system, gives a
repeated request one identity, retries only a failure that may pass, and
keeps those devices out of domain objects. It chooses a circuit breaker
or a bulkhead by how a dependency fails, and runs a process over several
aggregates or systems as a saga. The result is work that finishes or
fails knowably, and a repeat that cannot take the deposit twice.

## When to use

- A call to another system can hang, and its caller cannot wait for
  ever.
- A timed-out call may have done its work, and a repeat could do it
  twice.
- A dependency keeps failing, or is slow enough to hold every worker.
- A timeout, a retry, a circuit breaker or a bulkhead is about to be
  added.
- A business process spans several aggregates or systems, and a later
  step may fail after an earlier one committed.

## When not to use

- The call stays inside one process and cannot time out, such as a
  message from one domain object to another.
- The question is how a domain event reaches its handlers after the
  commit, or how an outbox sends it: that is
  [publishing domain events](../oo-publishing-domain-events/SKILL.md).
- The question is how an outside system's types and error codes are
  kept in its adapter: that is
  [crossing system boundaries](../oo-crossing-system-boundaries/SKILL.md).
- The question is two threads changing one object in memory: that is
  [managing shared state](../oo-managing-shared-state/SKILL.md).
- The question is which errors a method raises and who handles them:
  that is
  [designing failure behaviour](../oo-designing-failure-behaviour/SKILL.md).

## Core rules

1. Rule. **Bound every call to another system with a timeout chosen
   from how long its caller can wait, such as the minute a receptionist
   can keep a patient at the desk, and treat an expired timeout as an
   unknown outcome: the other system may have done the work.** A call
   with no bound holds its worker for as long as the other system
   hangs.

2. Rule. **Repeat only work that is safe to repeat.** Give each request
   an identity created once, before the first attempt, stored with the
   work it asks for and sent with every attempt, so the receiver
   answers a repeat with its first result instead of doing the work
   again. A handler of domain events checks the same way, as rule 5 of
   [publishing domain events](../oo-publishing-domain-events/SKILL.md)
   asks. Where the receiver cannot recognise a repeat, record what was
   sent and check for repeats afterwards, as the notice log does in the
   [designing aggregates reference on consistency][consistency].

3. Default. **Retry only a failure that may pass, such as an expired
   timeout or a busy reply, a bounded number of times, waiting longer
   before each attempt and adding a random part to each wait so that
   many callers do not retry together.** Never retry a refusal the
   other system declared, such as a declined card.

   The exception is an action a person started at a screen and is still
   waiting on: show the failure and let the person try again.

4. Rule. **Keep timeouts, retries, circuit breakers and bulkheads in
   the adapter for the outside system, or in an object that wraps the
   port and answers the same messages, never in a domain object.** The
   domain sends the port's messages and meets only the refusals the
   port declares, as rule 1 of
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   leaves the outside details to the adapter.

5. Judgement. **Add a circuit breaker for a dependency that keeps
   failing, and a bulkhead for one whose slowness would hold every
   worker.** A circuit breaker counts recent failures and, past a
   limit, fails each call at once for a while, then lets one trial call
   through and closes again if it succeeds. A bulkhead gives one
   dependency its own bounded pool of workers or connections, so a
   slow payment provider cannot take the workers the front desk needs.
   Each has a cost: an open breaker refuses calls the dependency might
   have answered, and its limit and its wait need tuning; a bulkhead
   holds workers idle while its dependency is quiet, and a pool sized
   too small refuses calls the dependency could take. What tips the
   balance is how the dependency fails: repeated failures call for a
   breaker, slow answers for a bulkhead, and a dependency that does both
   gets both.

6. Judgement. **Run a business process that spans several aggregates
   or systems as a saga: each step commits on its own, one aggregate in
   one transaction as rule 4 of
   [designing aggregates](../oo-designing-aggregates/SKILL.md) asks,
   and each step a later failure must undo has a compensating step,
   such as refunding a deposit when the room for its procedure cannot
   be reserved.** Let events join a short chain of steps that never
   branches, each handler reacting to the step before, as
   [publishing domain events](../oo-publishing-domain-events/SKILL.md)
   does. Give a process that branches, waits for a person or must show
   staff where it stands to a process manager, an object stored like an
   aggregate that reacts to each step's event and sends the next
   command. What tips the balance is the number of steps and branches,
   and whether anyone must see where the process stands.

## Pattern

Before, `ChargeDeposit` passes a patient and an amount straight to the
payments port. When the provider's answer does not arrive in time, the
queue that runs `ChargeDeposit` runs it again, the provider sees a new
charge, and the deposit is taken twice.

Before:

```text
interface Payments
  -- one charge for one deposit
  + charge(patient: PatientId, amount: Money): PaymentId
    raises CardDeclined

class ChargeDeposit
  - payments: Payments
  + new(payments: Payments)
  + run(patient: PatientId, amount: Money): PaymentId
    raises CardDeclined
    return payments.charge(patient, amount)
```

`Payments` declares `CardDeclined` on `charge`; no class implements
`Payments` in the fence. `Money` is taken to be an amount of money,
`PatientId` a patient's identity and `PaymentId` the provider's identity
for one charge. Each run sends one charge and stores nothing.

After, booking gives the deposit a `PaymentRequest` before any charge,
and every attempt of `ChargeDeposit` sends that request.

After:

```text
value PaymentRequest
  - id: PaymentRequestId
  - patient: PatientId
  - amount: Money
  + new(id: PaymentRequestId, patient: PatientId, amount: Money)

interface Payments
  + charge(request: PaymentRequest): PaymentId
    raises CardDeclined

class Deposit
  - id: DepositId
  - request: PaymentRequest
  + new(id: DepositId, request: PaymentRequest)
  + paymentRequest(): PaymentRequest
    return request

class ChargeDeposit
  - deposits: Deposits
  - payments: Payments
  + new(deposits: Deposits, payments: Payments)
  + run(id: DepositId): PaymentId
    raises CardDeclined
    deposit := deposits.find(id)
    return payments.charge(deposit.paymentRequest())
```

`Deposits` is taken to be the deposits' repository, whose `find` answers
the stored deposit. Booking stores the `Deposit`, with its
`PaymentRequest` and a new `PaymentRequestId`, under the `DepositId`, in
the clinic's store, in a transaction of its own, when it asks for the
deposit and before any charge; the fence leaves this out. The payments
adapter sends the request's identity to the provider as the key by which
the provider answers a repeat with the first charge, and reads the
request's fields through queries the fence leaves out. The retry itself,
in the adapter or in the queue that runs `run` again, is left out,
because the notation has no loop and cannot catch an error. Recording
that the deposit was taken is left out. `run` stores nothing. Every
attempt of one `Deposit` reads the same stored `PaymentRequest`, so the
provider answers every repeat with the first charge and takes the
deposit once.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A call to another system with no time limit.
- A retry with no limit, or with no wait between attempts.
- A repeated request that carries no identity the receiver can check.
- An expired timeout treated as proof that nothing happened.
- Retry or timeout code inside a domain object.
- A process over several systems with no step that undoes an earlier
  one.

## Common mistakes

- Retrying a refusal, such as a declined card.
- Creating a new request identity for each attempt.
- One shared pool of workers for every dependency.
- A circuit breaker for a call that fails once in a long while.
- A process manager for two steps that one event would join.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  makes each handler safe to receive the same event twice.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) keeps
  one aggregate in one transaction and brings a rule across aggregates
  true later.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md) puts
  a port beside the domain and an adapter behind it.
- [oo-crossing-system-boundaries](../oo-crossing-system-boundaries/SKILL.md)
  keeps a provider's types and error codes in its adapter.
- [oo-designing-failure-behaviour](../oo-designing-failure-behaviour/SKILL.md)
  chooses the errors a method raises and who handles them.
- [oo-managing-shared-state](../oo-managing-shared-state/SKILL.md) keeps
  one object safe for several threads.

## Further reading

- [Timeouts and retries](references/timeouts-and-retries.md)
- [Sagas and process managers](references/sagas-and-process-managers.md)

[consistency]: ../oo-designing-aggregates/references/consistency-across-aggregates.md#when-the-later-step-fails
