# Timeouts and retries

A call that leaves the clinic can wait for ever, fail after it has
changed something, or succeed without its answer arriving. The skill's
rules bound that wait and make a repeat harmless. This reference gives
the choices behind them.

## Choosing a timeout

Choose the bound from how long the caller can afford to wait, not from
how long the other system usually takes. A receptionist can keep a
patient at the desk for about a minute, so a call made during booking
gets a bound below that minute and leaves room to answer the patient. A
nightly report can wait several minutes. The bound is a limit on the
caller's patience, and a provider that needs longer than that has no
place in this flow.

Each call in a chain draws its own bound from the time left. A booking
that calls an insurer and then a payment provider cannot give each call
the whole minute the receptionist waits, or the second call can run
past the first one's end.

## An expired wait is an unknown outcome

A timeout says only that no answer arrived in time. The other system
may have done the work before its answer was lost, so the caller never
treats an expired wait as proof that nothing happened. If the work must
be known, ask the other system for its status, using the identity of
the request, or send the same request again and let the receiver
recognise it, as the next section describes.

## Failures that may pass

A failure may pass when the same request sent later could succeed: an
expired timeout, a busy reply, a connection dropped before an answer,
or a fault the other system reports as temporary. Those are the ones a
retry may ask again.

A refusal that the other system declared never passes on a retry: a
declined card, a request the other system rejects as invalid, or a
record it reports as absent when the request names it wrongly. Asking
again spends time and may repeat a refusal the person must hear, so the
caller passes it on at once.

## Retrying within a bound

A retry is bounded in number, not open-ended, and the waits between
attempts grow so a failing dependency is not hit at once by every
caller. In an example policy, three attempts in total is enough, with
waits of a second, then two seconds, up to a cap; each wait carries a
random part, such as up to half its length, so callers spread out
instead of retrying together. The numbers are an example, not a rule.

The bound also covers the whole call: when the caller's time is spent,
no further attempt starts, even when the attempt count allows one.

## The request identity

The Pattern's deposit carries a `PaymentRequest`, whose `id` is created
once, when booking asks for the deposit, and stored with it before any
charge. Every attempt sends the same identity. The provider keeps the
identity of each request it has charged and answers a repeat with the
first charge's `PaymentId` instead of taking the money again.

Where the receiver cannot recognise a repeat, record what was sent and
check for a repeat afterwards, as the notice log does in the designing
aggregates reference on consistency across aggregates.

## Circuit breakers and bulkheads

A circuit breaker has three states: closed, open and trying again.
Closed, it sends each call and counts recent failures; a caller meets
the dependency's own answer or failure. Open, for a while it fails
each call at once without sending it, so the caller meets a refusal
the port declares and can offer another time. Trying again, it lets
one trial call through; if the trial succeeds the breaker closes, and
if it fails the breaker opens for another while. While the trial runs,
the other callers meet the same immediate refusal.

A bulkhead gives one dependency its own bounded pool of workers or
connections. When the pool is full, a call waits for a free worker for
a bounded time or is refused; either way the other dependencies keep
their own pools. A slow payment provider then cannot take the workers
the front desk needs for booking.

## Where these live

A timeout, a retry, a breaker and a bulkhead all belong in the adapter
for the outside system, or in an object that wraps the port and answers
the same messages. The domain sends the port's messages and meets only
the refusals the port declares. An adapter or wrapper changes without
the domain knowing, and a test of a domain rule never waits on a
provider.

A retry waits between attempts, opens a breaker or catches an error;
the notation of this pack has no loop and cannot catch, so no fence
here shows one. The same holds for a status query sent after an expired
wait: it is another message to the port, bounded like every other call.
