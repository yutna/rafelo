# The outbox

- [Why sending at either moment fails](#why-sending-at-either-moment-fails)
- [The outbox and its relay](#the-outbox-and-its-relay)
- [A second handler](#a-second-handler)
- [A handler that changes an aggregate](#a-handler-that-changes-an-aggregate)

An event sent before its change commits can announce a change that then
rolls back. An event sent after the commit can be lost when the process
stops between the commit and the send. The outbox closes both gaps: the
change and the event are stored together, and a relay sends the stored
event afterwards and marks it.

## Why sending at either moment fails

A letter about a cancellation that never happened is worse than no
letter: the patient is told something untrue, and the clinic has to
correct it. A letter that never goes out because the process stopped
just after the commit is also a fault, and nothing retries it when no
record of the event exists. The outbox stores the change and the event
in one transaction, in the same database, so either both are stored or
neither is. The send then happens outside that transaction, from a
record that survives a stop.

## The outbox and its relay

The port stores events and hands them out one at a time. The relay reads
one, delivers it and marks it, and a later pass reads the next.

```text
interface Outbox
  + store(events: ReadOnlyList<DomainEvent>): void
  + nextUnsent(): StoredEvent?
  + markSent(id: EventId): void

value StoredEvent
  - id: EventId
  - event: DomainEvent
  + new(id: EventId, event: DomainEvent)
  + id(): EventId
    return id
  + event(): DomainEvent
    return event

interface EventDelivery
  + deliver(id: EventId, event: DomainEvent): void

class OutboxRelay
  - outbox: Outbox
  - delivery: EventDelivery
  + new(outbox: Outbox, delivery: EventDelivery)
  + sendNext(): void
    stored := outbox.nextUnsent()
    if stored = null then
      return
    else
      delivery.deliver(stored.id(), stored.event())
      outbox.markSent(stored.id())
    return
```

`store` gives each event a new `EventId` as it stores it, in the
transaction that stored the change, in the clinic's database.
`nextUnsent()` answers one stored event that has no mark, or `null` when
every stored event is marked. `markSent(id)` records that the event
stored under that identity has been handed on. `deliver` is taken to
send `handle(id, event)` to each handler that takes the event's type.
The relay runs outside any use case's transaction and stores nothing but
the mark. The constructor sets both fields before `sendNext` reads them,
and each pass delivers one event once and marks it once.

Each point where the work can stop leaves the change whole. Before the
commit, neither the change nor the event is stored. After the commit and
before the delivery, the event waits in the outbox and the next pass
sends it. After the delivery and before the mark, the next pass sends
the event again, so delivery is at least once, never exactly once. The
relay promises no order across aggregates, and a handler must accept the
same event more than once.

## A second handler

The letter is a handler of its own. It keeps the identities it has
already served, so a repeat finds its mark and returns without sending
again.

```text
class SendCancellationLetter
  - letters: Letters
  - sent: SentLetters
  + new(letters: Letters, sent: SentLetters)
  + handle(id: EventId, event: AppointmentCancelled): void
    if sent.contains(id) then
      return
    else
      letters.sendCancellation(event.appointment(), event.reason())
      sent.add(id)
    return
```

`SentLetters` is taken to answer `contains(id)` and to store an identity
through `add(id)`. What it stores is the identity of each event whose
letter went out, in the clinic's database, in a transaction of the
handler's own. `Letters.sendCancellation(appointment, reason)` is taken
to send one letter and change nothing in the aggregates. The constructor
sets both fields before `handle` reads them, and `handle` sends one
letter once and adds one identity once.

A stop between the send and the `add` sends a second letter on the next
delivery. A letter can afford that; a payment cannot, so a payment
handler would have the receiver refuse a second payment by the payment's
own identity.

## A handler that changes an aggregate

A handler that changes an aggregate stores the event's identity in the
same transaction as its change, so a repeat finds the identity and does
nothing; `ReleaseSlot` in the Pattern is this form. The other form
checks the state of what it changes, and it is enough only when a repeat
leaves nothing different, whatever happened in between.
