---
name: oo-crossing-system-boundaries
description: Use when an API or message must keep its shape as the model changes, when mapping partner data into the domain, or a contract needs a version.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Crossing System Boundaries

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Every system the clinic talks to keeps a model of its own. A partner
reads an appointment through an API, another organisation answers a
lookup, and a queue carries a message to code that runs later. Each of
those is a contract: a shape both sides agreed on, and a promise about
what a change may do to it. This skill gives each contract transfer
types of its own, maps them to the domain in one place per boundary,
wraps an outside API behind a port in the clinic's terms, and changes a
published contract only in ways its readers and writers survive. When a
change cannot be compatible, it versions the contract and retires the
old version on a schedule.

## When to use

- An API or message must keep its shape while the domain model changes.
- A partner's data has to become clinic values, or the clinic's answer
  has to become the partner's format.
- A published contract needs a version, or two versions must run side
  by side.
- A provider changes its API and the clinic must decide what else
  changes.
- A queued message, an outbox event, a cache or an exported file will
  be read by a later version of the code.

## When not to use

- The data never leaves the process and no other system or stored form
  reads it: pass domain objects as they are.
- The question is whether a type should be a class with rules or plain
  data: that is
  [deciding object or data](../oo-deciding-object-or-data/SKILL.md).
- The question is how a domain class reaches a database, a clock or
  another outside service at all: that is
  [inverting dependencies](../oo-inverting-dependencies/SKILL.md).
- The question is which team's model a boundary separates, and how the
  two teams relate: that is
  [bounding contexts](../oo-bounding-contexts/SKILL.md).
- The question is whether to publish a domain event, whether to record
  it in the aggregate, or how to deliver it after the commit: that is
  [publishing domain events](../oo-publishing-domain-events/SKILL.md).
  The stored shape that later code reads stays here, under rule 6.

## Core rules

1. Rule. **Give each contract with another system its own transfer
   types, owned by the adapter for that system and separate from the
   domain model.** The appointment a partner's app reads is a
   `PortalAppointment` with the fields the contract promises, not the
   domain's `Appointment` sent as it is. The domain can then rename a
   field or change a rule without breaking a reader, and the contract
   can change without reaching the model. A transfer object is plain
   data shaped by the contract and holds no rules; rule 3 of
   [deciding object or data](../oo-deciding-object-or-data/SKILL.md)
   decides that and converts it once at the edge.

2. Rule. **Map between a contract's transfer types and the domain's in
   one place for each boundary, in both directions.** The class that
   does this mapping is the mapper for that boundary. Incoming data
   becomes domain values through their constructors, which refuse what
   the domain cannot accept, and the domain's answer becomes the
   contract's types on the way out. A missing or unreadable field the
   clinic relies on is refused at the mapping, never passed on as an
   empty value for the domain to trip on later.

3. Rule. **Wrap another organisation's API behind a port that speaks
   the clinic's terms and asks only for what the clinic needs, with one
   adapter that alone knows the provider's types, error codes and
   calls.** This is rule 1 and rule 6 of
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md) and
   rule 3 of
   [hiding implementation](../oo-hiding-implementation/SKILL.md),
   applied to a provider outside the clinic. When the provider changes
   its API, the adapter and its tests are the only code that changes.

4. Default. **Change a published contract only in ways its existing
   readers and writers survive: add a field old readers may ignore,
   accept a new field only as optional, and never rename, remove or
   retype a field, or make an optional one required.** Read incoming
   data tolerantly: use the fields the clinic relies on and ignore the
   ones it does not know. The exception is a change that cannot be made
   compatible, such as a field whose meaning changes: it gets a new
   version.

5. Judgement. **When a change cannot be compatible, give the contract a
   new version, serve the old version beside the new one until its
   readers and writers have moved, and retire it on a schedule agreed
   with them; name the version where its readers can see it, in the
   address, in a header or in the message.** What tips the balance is
   how many readers there are and how quickly they can move: one
   reader the clinic controls can move in the same release, while
   partners need both versions for months.

6. Rule. **Treat what is stored to be read later as a contract with
   future code.** A queued message, an event in an outbox, a cached
   document or an exported file written today is read by a later
   version of the code, which must still read it, or must convert the
   stored data in a planned migration. The same compatibility rules
   then apply to a shape no reader sees at run time.

## Pattern

Before, `PortalFeed` sends the domain's `Appointment` itself to the
patient portal, so the portal reads the domain's field names and
renaming one breaks it.

Before:

```text
class PortalFeed
  - channel: PortalChannel
  + new(channel: PortalChannel)
  + publish(appointment: Appointment): void
    channel.send(appointment)
    return
```

After, `PortalFeed` sends a `PortalAppointment` built by one mapper, and
the portal reads only the fields the contract promises.

After:

```text
value PortalAppointment
  - appointmentId: String
  - startsAt: String
  - status: String
  + new(appointmentId: String, startsAt: String, status: String)

class PortalAppointmentMapper
  + toMessage(appointment: Appointment): PortalAppointment
    return new PortalAppointment(appointment.id().text(),
      appointment.startsAt().text(), appointment.status().text())

class PortalFeed
  - channel: PortalChannel
  - mapper: PortalAppointmentMapper
  + new(channel: PortalChannel, mapper: PortalAppointmentMapper)
  + publish(appointment: Appointment): void
    channel.send(mapper.toMessage(appointment))
    return
```

`startsAt()` and `status()` are queries this example adds to the
repositories skill's `Appointment`, `text()` is taken to answer each
value written as the contract's text, `channel.send` is taken to send
one message and change no aggregate, and the fences store nothing.

In both versions `publish` sends one message: the Before sends the
appointment itself once, and the After builds one `PortalAppointment`
and sends it once.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A domain class sent or returned as it is through a public API or a
  message.
- A domain class that carries a serialization format's markers or
  field names.
- A provider's types, error codes or client classes used outside the
  one adapter that talks to it.
- The same mapping between a partner's format and the domain written
  in more than one place.
- A renamed or removed field in a published reply, with no new
  version.
- A reader that fails on a field it does not know.

## Common mistakes

- Reusing one transfer type for several partners' contracts, so a
  change for one breaks the others.
- Putting business rules into transfer objects or mappers.
- Turning a missing field into a default value at the boundary instead
  of refusing it.
- Starting a new version for every change, compatible or not.
- Changing the shape of stored messages with no plan for those already
  stored.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-deciding-object-or-data](../oo-deciding-object-or-data/SKILL.md)
  rule 3 keeps a transfer object free of rules and converts it once at
  the edge.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  rules 1 and 6 put a provider behind a port the domain owns, shaped by
  the domain's need.
- [oo-hiding-implementation](../oo-hiding-implementation/SKILL.md)
  rule 3 keeps a provider's types and errors behind the adapter.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) rule 4
  decides where a context translates another model at its edge; this
  skill says how that translation is written.
- [oo-publishing-domain-events](../oo-publishing-domain-events/SKILL.md)
  rule 4 stores an outbox event, which is also a stored message read
  later.

## Further reading

- [Changing a contract](references/changing-a-contract.md)
- [Wrapping an outside API](references/wrapping-an-outside-api.md)
