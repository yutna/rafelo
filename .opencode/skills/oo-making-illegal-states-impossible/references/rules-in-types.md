# Rules in types

A rule that reads only the fields of one value belongs in that value's
constructor. The constructor runs once, refuses a broken value, and
every holder then trusts the rule. A rule that reads other objects or
the clock is different: it can change while the object sits still, so
it belongs where the action happens.

## A value that refuses a broken length

`Duration` holds minutes and accepts no negative length. The constructor
checks the length before it sets the field, so a negative duration has
no instance to reach a caller.

```text
value Duration
  - minutes: Int
  + new(length: Int)
    raises NegativeDuration
    if length.isNegative() then
      raise NegativeDuration
    else
      minutes := length
```

`length.isNegative()` is taken to answer true when the length is below
zero. The `if` has an `else`, so the only path that finishes sets
`minutes` once. A caller that catches `NegativeDuration` knows which
rule failed.

## A range whose end follows its start

A time range has two fields that must agree. `TimeRange` keeps the two
fields and the constructor the coupling skill declares; the `raises`
line and the body that checks the order are the one difference.

```text
value TimeRange
  - startsAt: DateTime
  - endsAt: DateTime
  + new(startsAt: DateTime, endsAt: DateTime)
    raises EndNotAfterStart
    if startsAt.isAtOrAfter(endsAt) then
      raise EndNotAfterStart
```

`startsAt.isAtOrAfter(endsAt)` is taken to answer true when the start
is the same as the end or later. The constructor parameters are named
for the fields, so a range that passes the check has both fields set.
The check runs once, at construction; no holder compares the two times
again.

## Where a type stops

Whether a slot is free now depends on other bookings and on the current
time. A `TimeRange` cannot carry that rule: the range can stay the same
while the answer changes, and a value that held the answer would go
stale. The check belongs at the action that needs it. `Slot.reserve` in
the notation checks the slot when a booking asks for it and raises
`SlotTaken`; the caller does not test the slot first.

```text
class AppointmentBooking
  + book(slot: Slot, patient: PatientId): void
    raises SlotTaken
    slot.reserve(patient)
    return
```

`Slot.reserve` is the notation's message: it sets the patient once when
the slot is free and raises `SlotTaken` otherwise. `AppointmentBooking`
sends it once, so the side effect happens once. A rule about another
object or about the clock stays at the action, where the answer is
current.
