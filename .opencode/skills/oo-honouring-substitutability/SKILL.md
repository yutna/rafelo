---
name: oo-honouring-substitutability
description: Use when a subclass throws or breaks its parent's promise, when callers check which subtype they hold, or when deciding if a class may be extended.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Honouring Substitutability

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A subtype stands in for its parent only when it keeps the parent's
contract. Callers are written against that contract: the inputs the parent
accepts, the result and the state it promises, and the errors it allows.
A subtype that accepts less, delivers less or raises more breaks those
callers without changing a line of their code. This skill decides what a
type promises, whether each subtype keeps that promise, and whether a
class should be extended at all.

## When to use

- A subclass overrides a parent method and behaves differently from it.
- Callers check which subtype they hold before sending a message.
- A subtype raises an error, or refuses an input, that its parent accepts.
- Two classes share a signature but not the same promise.
- A class is about to be opened to subclasses, or closed to them.
- Tests written for a parent type fail for one of its subtypes.

## When not to use

- The subtype only wants its parent's code and is never used where the
  parent is expected. That is a question of reuse, not of
  substitutability.
- The checks read a type code, an enum or a status field, or cover a
  closed set of cases built for exhaustive matching. That is the work of
  replacing conditionals with polymorphism, and it is not this skill.
- The type has no subtypes and is already closed to extension. There is
  no substitute to honour and no class to open.

## Core rules

1. Rule. **Make every subtype usable wherever its parent type is expected,
   without the caller knowing which subtype it holds.** Callers are
   written against the parent's promises, so a subtype that breaks one
   breaks them silently. A class that implements an interface is bound by
   the same promise as a subclass.

2. Rule. **Never strengthen a precondition in a subtype: accept at least
   every input the parent accepts, in every state in which the parent
   accepts it.** A subtype may accept more than its parent, never less.

3. Rule. **Never weaken a postcondition or drop an invariant in a
   subtype: deliver at least what the parent guarantees, keep every
   invariant the parent keeps, and raise no error the parent's contract
   does not allow.** A subtype that returns a different kind of answer,
   or leaves the object in a state the parent forbids, breaks callers as
   surely as a stronger precondition does.

4. Default. **Write a type's contract where its callers read it: what
   each method requires, what it guarantees, and what stays true between
   calls.** In the notation that is a `--` comment under the signature,
   after any `raises` line. A contract kept only in the parent's code is
   easy for a subclass author to miss.

   The exception is a method whose name, types and `raises` line already
   say all of it, such as a query that accepts any input.

5. Default. **Close a class to extension unless it was built for it.**
   Built for it means the methods a subclass may override are named,
   each with the contract an override must keep written beside it, and
   which of the class's own methods send them. An open class that names
   no such method invites overrides its author never meant to support.

   The exception is a framework that must extend the class at run time,
   such as a proxy for lazy loading: leave it open and say in the code
   why.

6. Default. **When code checks which subtype it holds before sending a
   message, fix the subtype or the hierarchy, not the caller.** The check
   is the visible sign that a subtype breaks its parent's contract, so
   patching the caller that checks does not cure the subtype.

   The exception is a closed set of cases built for exhaustive matching,
   where each match handles every case and the compiler lists a missing
   one.

7. Judgement. **When a subtype cannot keep its parent's contract, either
   widen the parent's contract for every subtype or stop extending the
   parent.** What tips the balance is whether the parent's callers must
   handle the new case too: if they must, widen the contract and update
   them; if they never meet it, hold the parent instead of extending it.

## Pattern

Before, `SmsChannel` requires a mobile number its interface never asked
for, so a run stops at the first patient without one. After, it hands
that reminder to a channel it holds.

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

interface ReminderChannel
  + send(reminder: Reminder): void
    -- delivers the reminder or hands it on, and raises nothing

class EmailChannel implements ReminderChannel
  - mailer: Mailer
  + new(mailer: Mailer)
  + send(reminder: Reminder): void
    mailer.send(reminder.patient(), reminder.text())
    return

class SmsChannel implements ReminderChannel
  - gateway: SmsGateway
  + new(gateway: SmsGateway)
  + send(reminder: Reminder): void
    raises NoMobileNumber
    mobile := reminder.mobile()
    if mobile = null then
      raise NoMobileNumber
    else
      gateway.sendText(mobile, reminder.text())
    return

class ReminderRun
  - channel: ReminderChannel
  + new(channel: ReminderChannel)
  + run(reminders: List<Reminder>): void
    reminders.sendEach(channel)
    return
```

The interface comment says a send delivers the reminder or hands it on,
and raises nothing. `EmailChannel` keeps that promise. `SmsChannel`
raises `NoMobileNumber` when `reminder.mobile()` is `null`, an error the
interface does not allow, and it requires a mobile number the interface
never asked for. `ReminderRun` holds a `ReminderChannel`, so the error
from the first reminder without a mobile number ends its run and the
later reminders are never sent.

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

interface ReminderChannel
  + send(reminder: Reminder): void
    -- delivers the reminder or hands it on, and raises nothing

class EmailChannel implements ReminderChannel
  - mailer: Mailer
  + new(mailer: Mailer)
  + send(reminder: Reminder): void
    mailer.send(reminder.patient(), reminder.text())
    return

class SmsChannel implements ReminderChannel
  - gateway: SmsGateway
  - fallback: ReminderChannel
  + new(gateway: SmsGateway, fallback: ReminderChannel)
  + send(reminder: Reminder): void
    mobile := reminder.mobile()
    if mobile = null then
      fallback.send(reminder)
    else
      gateway.sendText(mobile, reminder.text())
    return

class ReminderRun
  - channel: ReminderChannel
  + new(channel: ReminderChannel)
  + run(reminders: List<Reminder>): void
    reminders.sendEach(channel)
    return
```

In the After, `SmsChannel` holds a second `ReminderChannel` as
`fallback`, set by its constructor before `send` reads it. A reminder
with no mobile number goes to the fallback; every other reminder goes to
the gateway once. `SmsChannel` accepts every reminder the interface
accepts, raises nothing, and sends each reminder exactly once.
`EmailChannel` and `ReminderRun` are unchanged. `mailer.send` is taken to
email the reminder text to the patient, `gateway.sendText` to send it as
a text message to that number, and `reminders.sendEach(channel)` to send
`channel.send(reminder)` once for each reminder in order, stopping at the
first error.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- An override that raises an error the parent's method never raises.
- An override with an empty body, or one that ignores its input.
- A caller that checks an object's class before sending it a message.
- A subtype method that needs a field or a state its parent's method does
  not.
- Tests written for the parent type that a subtype fails.

## Common mistakes

- Fixing a broken subtype by adding type checks to every caller.
- Treating a matching signature as a kept contract.
- Leaving a contract only in the parent's code, where a subclass author
  never reads it.
- Leaving a class open to extension with no overridable methods named.
- Widening a parent's contract for one subtype without updating the
  callers that relied on the narrow one.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-choosing-composition-over-inheritance](../oo-choosing-composition-over-inheritance/SKILL.md)
  chooses between extending a class and holding it, which is where a
  subtype that cannot keep its promise ends up.

## Further reading

- [Contracts and extension](references/contracts.md)
