---
name: oo-designing-failure-behaviour
description: Use when a method answers null for nothing found, when callers ignore or catch every exception, or when designing a module's error types.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Failure Behaviour

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

When a method cannot do its job it has to tell someone. The ways it can
tell differ: refuse in the clinic's words, report that no value exists,
or stop because nothing above can repair the failure. This skill chooses
among them, groups a module's refusals under one base, checks
preconditions before any change, and translates an error only where it
crosses a boundary. The result is a caller that hears every refusal it
must act on and no fault it cannot repair.

## When to use

- A method answers `null` when it finds nothing.
- Callers ignore a returned success flag, a number or a message.
- Callers catch every exception and carry on.
- A module's error types are being designed or grouped.
- An absent value reaches callers that each decide differently.
- A method may change several fields before it finds a bad input.

## When not to use

- The question is which errors a subclass may raise compared with its
  parent. That is
  [honouring substitutability](../oo-honouring-substitutability/SKILL.md)
  rule 3.
- The code is an adapter's handling of one provider's error codes, or
  how it maps them into the port's terms. That is
  [crossing system boundaries](../oo-crossing-system-boundaries/SKILL.md)
  and [hiding implementation](../oo-hiding-implementation/SKILL.md).
- The question is whether a call that would change nothing should fail
  at all. That is
  [hiding implementation](../oo-hiding-implementation/SKILL.md) rule 4.
- The code can neither refuse nor find nothing, such as a calculation
  over values that are already checked.
- The question is retrying or timing out a call to another system. That
  is [making work reliable](../oo-making-work-reliable/SKILL.md), which
  bounds the call and decides what a retry may repeat.

## Core rules

1. Rule. **When a command cannot do what it was asked because a clinic
   rule refuses it, raise an error named in the clinic's words for that
   refusal, such as `SlotTaken`, and declare it on the method's
   `raises` line.** Never answer a success flag, a number or a message
   that the caller may ignore. A refusal the caller never hears of
   leaves the desk believing in a booking that was never made. Modeling
   lifecycles, rule 2, names a refused transition this way; this rule
   covers every refusal. Whether a call that would change nothing is
   refused at all is hiding implementation, rule 4.

2. Judgement. **Tell a refusal from a fault.** A refusal is an outcome
   of the clinic's rules that the immediate caller can act on, such as
   offering another time when `SlotTaken` is raised: declare it on each
   method its caller must handle it from, and let that caller handle
   it. A fault is a failure no caller can repair, such as a broken
   invariant or a store that does not answer: only the method that
   raises it itself declares it, as
   [the notation](../oo-design/references/notation.md) asks of every
   `raise`, together with the port that method implements; every method
   above passes it on undeclared, up to one handler at the program's
   edge, such as the request handler, which records it and answers a
   general failure. What tips the balance is whether the immediate
   caller would do anything different on hearing of it. Which errors a
   language makes its callers declare is outside this skill; `oo-java`
   rules 4 and 5 decide it for Java.

3. Default. **Give the refusals one module raises a common base error
   named for what the module refuses, such as `BookingRefused`, with
   one error type per refusal that callers treat apart, so a caller
   handles one refusal by its name or all of them by the base.** Never
   one error with a code field that callers in several places test,
   which is the conditional that
   [replacing conditionals with polymorphism](../oo-replacing-conditionals-with-polymorphism/SKILL.md)
   rule 1 removes. A port still lists on its `raises` line each refusal
   its implementations raise, by name.

   The exception is a module with a single refusal: it needs no base.

4. Rule. **Check a method's preconditions before it changes anything,
   and raise at once when one fails: a method that finds a broken
   precondition after it has changed a field leaves the object
   half-changed.** Never carry a value known to be wrong into a later
   step, where it fails far from its cause. A constructor does the same
   for its input, as
   [constructing valid objects](../oo-constructing-valid-objects/SKILL.md)
   rule 3 asks.

5. Rule. **Never answer an absent value through a type that does not
   say it may be absent.** Where each caller decides for itself what
   absence means, declare the optional type, `Type?`, so the caller
   must decide; where absence is an error, raise, as
   [the repositories skill](../oo-designing-repositories/SKILL.md)'s
   `find` raises `AppointmentNotFound`; where every caller would do the
   same for the absent case, answer a special case, as rule 6 says.

6. Default. **Answer a special case where every caller would treat an
   absent or unusual value alike: an object of the same type that gives
   that case's answer, such as self-pay for a patient with no insurer,
   which answers the whole fee as the patient's share.** A null object
   is the special case whose answer is to do nothing. Callers then send
   the message with no check, and the rule for the case lives in one
   class. A special case keeps every promise of its type, as
   [honouring substitutability](../oo-honouring-substitutability/SKILL.md)
   rule 3 asks, so a null object stands only where doing nothing keeps
   them.

   The exception is an absence that callers treat differently, or that
   a caller must report: declare `Type?` or raise, as rule 5 says.

7. Rule. **Translate an error where it crosses a boundary, and nowhere
   else: the adapter behind a port turns an outside system's failure
   into a refusal the port declares, in the clinic's words, or lets it
   pass as a fault, as
   [hiding implementation](../oo-hiding-implementation/SKILL.md) rule 3,
   and
   [crossing system boundaries](../oo-crossing-system-boundaries/SKILL.md)
   rule 3, keep a provider's errors in its adapter.** A layer in between
   that catches an error only to raise another gives its caller nothing
   more to act on.

## Pattern

Before, `BillingAccount` holds an optional policy, and every method that
needs the policy tests it for `null` first. After, a `Payer` answers the
same two questions for an insured and for a self-pay patient, and the
account holds one `Payer` and never a `null`.

Before:

```text
value InsurancePolicy
  - copayShare: Percentage
  + new(copayShare: Percentage)
  + patientShareOf(fee: Money): Money
    return fee.portion(copayShare)
  + insurerShareOf(fee: Money): Money
    return fee.minus(patientShareOf(fee))

class BillingAccount
  - policy: InsurancePolicy?
  + new(policy: InsurancePolicy?)
  + patientShareOf(fee: Money): Money
    if policy = null then
      return fee
    else
      return policy.patientShareOf(fee)
  + insurerShareOf(fee: Money): Money
    if policy = null then
      return Money.zero()
    else
      return policy.insurerShareOf(fee)
```

`Money` and `Percentage` are taken to be a money amount and a share of
it. `fee.portion(share)` is taken to mean that share of the fee,
`fee.minus(amount)` the fee less the amount, and `Money.zero()` no
money. Every method and every caller that needs the policy repeats the
`null` check, and one that forgets it fails on `null`.

After:

```text
interface Payer
  -- the two shares make up the fee
  + patientShareOf(fee: Money): Money
  + insurerShareOf(fee: Money): Money

value InsurancePolicy implements Payer
  - copayShare: Percentage
  + new(copayShare: Percentage)
  + patientShareOf(fee: Money): Money
    return fee.portion(copayShare)
  + insurerShareOf(fee: Money): Money
    return fee.minus(patientShareOf(fee))

value SelfPay implements Payer
  + new()
  + patientShareOf(fee: Money): Money
    return fee
  + insurerShareOf(fee: Money): Money
    return Money.zero()

class BillingAccount
  - payer: Payer
  + new(payer: Payer)
  + patientShareOf(fee: Money): Money
    return payer.patientShareOf(fee)
  + insurerShareOf(fee: Money): Money
    return payer.insurerShareOf(fee)
```

`InsurancePolicy` keeps its field, constructor and both methods.
`SelfPay` has no field, and its constructor sets nothing. `SelfPay` is
the special case of rule 6 and keeps `Payer`'s promise that the two
shares make up the fee. The code that opens an account passes
`new SelfPay()` when the patient has no insurer, so no account holds
`null`; that code is left out of the fence. Nothing raises and nothing
is stored.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A method whose declared result does not say it may be absent, but
  that answers `null`.
- A command that answers a number or a flag for success.
- An error type with a code field that callers test.
- A catch that swallows every error and carries on.
- A method that changes a field before it checks its precondition.
- The same check for an absent value repeated in every caller.

## Common mistakes

- Raising an error for an answer every caller expects, such as no
  appointments today, where an empty list answers it.
- Declaring a fault, such as a store that does not answer, on every
  method it passes through.
- Answering a null object where a caller must learn that the value is
  missing.
- One base error for the whole system rather than one per module.
- Catching an error only to raise another that tells the caller nothing
  more.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-hiding-implementation](../oo-hiding-implementation/SKILL.md)
  keeps a provider's types and errors behind its adapter.
- [oo-crossing-system-boundaries](../oo-crossing-system-boundaries/SKILL.md)
  decides which errors a port declares where a provider's API is wrapped.
- [oo-honouring-substitutability](../oo-honouring-substitutability/SKILL.md)
  keeps a special case within its type's promise.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  checks a constructor's input before the object exists.
- [oo-modeling-lifecycles](../oo-modeling-lifecycles/SKILL.md) names a
  refused transition with the error for it.

## Further reading

- [Refusals and faults](references/refusals-and-faults.md)
- [Absence](references/absence.md)
