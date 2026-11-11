---
name: oo-managing-shared-state
description: Use when several threads or tasks use one object at once, when a cache or counter goes wrong under load, or when choosing locks or one owner.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Managing Shared State

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Some state is reached by more than one thread or task at once. This skill
keeps such state safe in three ways: it shares values that never change,
confines changing state to one owner, and guards the rest with a lock. It
adds the handoff that keeps a half-built object from another thread, the
written policy a review can check, and the choice between a monitor
object and an active object. The result is state that loses no change,
and a caller that does not wait behind another's slow call.

## When to use

- Several threads or tasks read and change one object at once.
- A counter, cache or collection loses changes when the load rises.
- A constructor hands its object to another thread or a shared field.
- More than one thread reaches a class's fields, and no note says how
  they are kept safe.
- A lock is about to be added, or one piece of state needs one owner.
- A choice between a monitor object and an active object is due.

## When not to use

- Two requests or processes change the state through the store, such as
  two receptionists saving one appointment. That is
  [designing aggregates](../oo-designing-aggregates/SKILL.md).
- The question is which thread may touch a screen. That is rule 6 of
  [separating presentation from domain](../oo-separating-presentation-from-domain/SKILL.md).
- No object is reached by more than one thread or task, such as a
  service whose requests share nothing but the store.
- The question is retrying or timing out a call to another system. That
  is [making work reliable](../oo-making-work-reliable/SKILL.md), which
  chooses the timeout and when a retry is safe.

## Core rules

1. Default. **Share immutable values between threads and tasks.** A value
   whose fields never change can be read by any number of them at once
   with no lock, as rule 2 of
   [modeling values and entities](../oo-modeling-values-and-entities/SKILL.md)
   makes every value. A change builds a new value and puts it in place of
   the old one whole.

   The exception is state that changes so often that building a new value
   each time costs too much, such as a count of arrivals: confine it, as
   rule 2 says, or guard it, as rule 5 says.

2. Rule. **Confine each piece of changing state to one owner.** One
   thread, one task or one request reads and writes it, and any other
   part asks the owner by a message. State only its owner touches needs
   no lock. The objects one request loads, such as the appointment a use
   case changes, belong to that request alone; changes between requests
   meet in the store, where
   [designing aggregates](../oo-designing-aggregates/SKILL.md) checks a
   version and refuses the second of two saves made from stale copies.

3. Rule. **Hand an object to another thread only when it is complete, and
   only through a handoff the language makes safe.** Such a handoff is a
   queue built for threads, a field written and read under one lock, or a
   reference the language publishes whole. Never let a constructor hand
   out the object it is building, and never put a half-built object in a
   shared field. Another thread can otherwise see fields the constructor
   has not set. Rule 1 of
   [constructing valid objects](../oo-constructing-valid-objects/SKILL.md)
   makes an object complete when its constructor ends; this rule keeps
   any other thread from seeing it sooner.

4. Rule. **Write down the synchronisation policy of every class whose
   changing state more than one thread reaches.** Say which fields are
   shared, which lock or owner guards each, and which methods must hold
   it, beside the class where its readers see it. Without that note a
   review cannot check the class, and the next change breaks it unseen.

5. Rule. **Make a check and the change it guards one step.** The object
   that holds the state checks it and changes it inside one method, under
   one lock held for the whole method, so no other thread changes the
   state in between. A caller never checks in one message and changes in
   another: a slot found free in one message and reserved in the next can
   be reserved twice in between. Rule 3 of
   [encapsulating state and behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
   already tells the object rather than asking it; under threads, asking
   first is also a race.

6. Judgement. **Choose between a monitor object and an active object.** A
   monitor object holds its state and one lock, and each caller waits
   while one of its methods runs. An active object owns its state on a
   thread or task of its own, takes requests from a queue, and answers
   each with a reply the caller collects later. What tips the balance is
   how long the work under the lock takes and whether callers can wait: a
   short check and change suits a monitor, while slow work, such as a
   call to another system, suits an active object, so no caller waits
   behind another's slow call. Never call another system or another
   locked object while holding a monitor's lock. Which thread may touch a
   screen is rule 6 of
   [separating presentation from domain](../oo-separating-presentation-from-domain/SKILL.md);
   that choice belongs there, not here.

## Pattern

Before, `FreeTimesCache` holds one clinician's free times today for
request threads to read, while a background job refreshes it in place.
After, the free times are a `FreeTimes` value that never changes, and the
cache holds the current one and replaces it whole.

Before:

```text
class FreeTimesCache
  - times: List<DateTime>
  + new()
    times := new List<DateTime>()
  + refresh(fresh: List<DateTime>): void
    times.clear()
    times.addAll(fresh)
  + freeTimes(): List<DateTime>
    return times.copy()
```

`clear` and `addAll` are taken to empty the list and to add each time in
turn, so a request that reads between them sees an empty day, and a copy
taken while `addAll` runs reads a list another thread is changing.

After:

```text
value FreeTimes
  - times: List<DateTime>
  + new(given: List<DateTime>)
    times := given.copy()
  + all(): ReadOnlyList<DateTime>
    return times.readOnlyView()

class FreeTimesCache
  -- current is shared, replaced whole and never changed in place, so no
  -- lock guards it
  - current: FreeTimes
  + new(initial: FreeTimes)
    current := initial
  + refresh(fresh: FreeTimes): void
    current := fresh
  + freeTimes(): ReadOnlyList<DateTime>
    return current.all()
```

`current := fresh` is taken to publish the new `FreeTimes` to every thread
whole, through the language's own construct for a reference threads
share; this skill names no language. A reader gets the old day or the new
one, never a mixture. The background job builds each `FreeTimes` before
it sends `refresh`. `ReadOnlyList` is the notation's. Nothing is stored:
the cache lives in memory and no transaction is opened. Each version
answers one clinician's free times, and only `refresh` changes the cache.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A field that more than one thread changes, with no written policy
  beside its class.
- A check in one message and the change it guards in another.
- A collection rebuilt in place while other threads read it.
- A constructor that hands its object to another thread or a shared
  field.
- A lock held while calling another system or another locked object.
- A value object with a field that can change.

## Common mistakes

- Adding a lock to every method of a class that no other thread reaches.
- Making each field safe on its own while a rule spans two of them.
- Handing an entity one request loaded to another request instead of
  loading it again.
- Guarding with a lock in memory what two processes change through the
  store.
- Waiting for an active object's reply on the active object's own thread.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)
  makes a value immutable, so no holder sees another's change.
- [oo-constructing-valid-objects](../oo-constructing-valid-objects/SKILL.md)
  makes an object complete when its constructor ends.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  tells the object what to do rather than asking for its state.
- [oo-designing-aggregates](../oo-designing-aggregates/SKILL.md) checks a
  version and refuses a save made from a stale copy.
- [oo-separating-presentation-from-domain](../oo-separating-presentation-from-domain/SKILL.md)
  decides which thread may touch a screen.

## Further reading

- [Confinement and handoff](references/confinement-and-handoff.md)
- [Monitors and active objects](references/monitors-and-active-objects.md)
