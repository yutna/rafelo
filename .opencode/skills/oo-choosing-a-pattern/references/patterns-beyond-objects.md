# Patterns beyond objects

The application patterns this pack treats live in the skills that own
them, such as [designing
repositories](../../oo-designing-repositories/SKILL.md) and [publishing
domain events](../../oo-publishing-domain-events/SKILL.md); this reference
lists none of them.

The patterns below are outside this skill. They arrange messages between
systems or keep a system up when a dependency fails.

## Messages between systems

Each of these seven patterns starts from one symptom at the edge of
the clinic. Each entry gives the symptom, the force and the cost.

- **Channel.** A lab result leaves without the sender naming the lab.
  The force is a sender that must not know where its receiver lives,
  and a receiver that may be down when the result is sent. The cost is
  a broker to run and watch, and a message that can arrive late or
  twice.

- **Publish and Subscribe.** Billing hears of a cancellation without
  being named. The force is one fact with several readers, where a new
  reader must not change the publisher. The cost is a publisher that
  cannot see who reacts, so only a subscriber notices its own failure,
  and a message shape that every reader now relies on.

- **Request and Reply.** Booking waits for an insurer's answer before
  it finishes. The force is a sender that needs the answer to finish
  its own work. The cost is a wait that fails when the insurer is slow
  or down unless it is bounded, and an identity on each reply that
  matches it to its request.

- **Competing Consumers.** Several workers take from one reminder
  queue, and each message goes to one of them at a time. The force is
  more messages than one worker can handle in time. The cost is that
  two messages may finish in another order than they arrived, so the
  work must not depend on that order.

- **Idempotent Receiver.** A repeated message changes nothing the
  second time. The force is a channel that may deliver one message more
  than once. The cost is a check before every change: the receiver
  keeps the identity of each message it has handled, or reads the state
  the message would change.

- **Dead-letter Channel.** A message no handler can process is kept for
  a person. The force is a message that would otherwise be retried for
  ever or hold up the messages behind it. The cost is a person who must
  watch that channel and decide each message, and a message that waits
  there until they do.

- **Message Translator.** A partner's `encounter` becomes the clinic's
  visit. The force is two systems that name or shape one thing
  differently, where neither will change. The cost is one more mapping
  to keep in step with both sides.

None of these messages is this skill's to decide.

## When a dependency fails

A failing dependency is a different problem. A timeout bounds the wait
for an answer; retries ask again after a failure that may pass; a
circuit breaker stops asking a dependency that keeps failing and tries
again later; a bulkhead keeps one slow dependency from using every
worker. Those patterns are outside this skill, and
[making work reliable](../../oo-making-work-reliable/SKILL.md) treats
them.
