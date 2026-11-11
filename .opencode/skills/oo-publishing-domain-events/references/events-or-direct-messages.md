# Events or direct messages

An event and a direct message both carry a change to another part. The
event is published after the commit and runs its reaction later; the
direct message is sent during the use case and its answer is part of
that use case. The three clinic cases below show what decides.

## Three cases side by side

|Case|What decides it|
|---|---|
|Booking|The slot must be reserved first, so one transaction.|
|Cancelling|The change is complete without the letter, so handlers.|
|A fee in the reply|The caller needs the fee before it answers, so a message.|

Booking needs the slot reserved before the appointment exists. A refusal
has to stop the booking, and the caller has to know now, so booking
sends the slot a direct message inside one transaction. That is the
exception of designing aggregates, rule 4: the appointment is new, and
a conflict on the slot should refuse the whole change.

Cancelling is complete once the appointment and its event are stored. The
letter follows the cancellation, and the slot is released and stored
later, by a handler of its own. The waiting-list offer reacts to the
slot's release, not to the cancellation, so a slot is never offered
while it is still held. Each reaction runs after the commit in a
transaction of its own, and none can refuse the cancellation; a failure
in one does not undo it.

A cancellation fee that the reply must state is different. The caller
cannot finish its work without the number, so the use case asks for it
inside the transaction and returns it. Waiting for a handler would leave
the reply incomplete, and a handler that failed would leave the caller
with nothing to say.

## What the reply says while handlers have not run

The reply states what has happened, not what will. After a cancellation
it says that the appointment is cancelled and that a letter will follow;
it does not say that the letter has gone out. The cancellation is
stored, the handlers may still be waiting or may fail and run again, and
the reply would otherwise claim a fact it cannot know.

When the caller must be told that a reaction succeeded, the reaction is
not a handler for that use case. It is a direct message sent before the
reply, or the reply waits for its outcome.

## One handler per reaction

Each handler takes one reaction and is named for it, such as
`ReleaseSlot` or `SendCancellationLetter`. A letter and a waiting-list
offer are two handlers, not two steps of one: if the letter fails, the
offer is not sent a second time. A handler that performed several
unrelated reactions would repeat all of them when one failed.

## An event is not the history of transitions

An event is not the history that modeling lifecycles, rule 6, keeps
inside the aggregate: `AppointmentChange` entries record when and why a
transition happened for a report, while a domain event is handed to
handlers after the commit and may arrive more than once.

## A domain event is not a message to another system

A message that another organisation's system reads has a shape and a
version that both sides agree on, and a change to it is a change to that
agreement. That shape is a contract at the boundary between the systems,
one that [crossing system
boundaries](../../oo-crossing-system-boundaries/SKILL.md) gives its own
transfer types and a version. A domain event is written in the clinic's
words and carries what the handlers in the clinic need.
