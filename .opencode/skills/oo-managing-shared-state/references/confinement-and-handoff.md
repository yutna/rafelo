# Confinement and handoff

## Three ways to keep shared state safe

State that more than one thread or task reaches is kept safe in one of
three ways.

- **Share a value that never changes.** The scheduling job builds the
  list of today's rooms as a fresh list of `RoomId` values every morning
  and puts it in place whole. Each request thread reads that list and
  none changes it. When a room closes for repair, the job builds a new
  list without that room and puts the new list in place of the old one,
  so a reader holds either the old list or the new one.
- **Confine changing state to one owner.** The appointment a booking
  request loads belongs to that request alone. No other request holds
  the same object, so the request changes it with no lock. A second
  request loads the appointment again, and the two changes meet in the
  store rather than in one shared object.
- **Guard changing state with a lock.** The count of patients checked in
  today is one number that each check-in changes. `CheckInCount` holds
  that number and one lock, and its `checkIn(patient: PatientId)` method
  records the patient and increases the count in one step, with the lock
  held for the whole method. A caller that only reads the count calls
  `count()`, which holds the same lock.

The three ways are not interchangeable. A value is shared only after it
is complete, and a list that is still being built is not shared. An
owner that hands its state out gives up the confinement. A lock that is
not held for the whole check and change leaves the race in place.

## What another thread may see before a constructor ends

An object is complete when its constructor ends, as rule 1 of
[constructing valid objects](../../oo-constructing-valid-objects/SKILL.md)
asks. Before that point its fields hold whatever the language gives a
field with no value yet, and its invariants may not hold.

A reference that leaves the constructor early lets another thread reach
the object in that state. A constructor that starts a thread with the
object, stores it in a shared field, or passes it to a callback hands out
a half-built object. The other thread can then read a patient with no
identifier, or a list the constructor has not filled.

The handoffs that prevent it all wait for the constructor to end. One
builds the object first and only then writes its reference into a shared
field, under the lock that guards that field. Another puts the finished
object on a queue built for threads, which carries it to its new owner.
A third builds the object inside the thread or task that will own it and
never shares it at all. A constructor starts no thread of its own and
puts its object in no field another thread can reach.

## A written synchronisation policy

A class whose changing state more than one thread reaches carries a note
beside it. The note answers three questions: which fields are shared,
which lock or owner guards each one, and which methods must hold it.
For `CheckInCount`, the note reads: `count` is shared by every check-in
thread; the object's own lock guards it; `checkIn` and `count` hold the
lock for the whole method; no other method reads or writes the field.

The note sits where the class's readers meet it, at the class's
declaration. A reader who adds a method can then see whether the new
method must take the lock before touching a field, and a reviewer can
check that every shared field has one guard.

## Changes between requests meet in the store

Two requests never share the object they loaded, so a lock cannot order
them. The store does. The appointment loaded by one request carries the
version it was read with, and the save compares that version with the
one the store holds. When another request has saved in between, the
versions differ and the store refuses the second save instead of
overwriting the first change. The request then loads the appointment
again, repeats its change on the current copy, and saves once more.

This is the version check that
[designing aggregates](../../oo-designing-aggregates/SKILL.md) treats. A
lock in one process cannot order two processes, cannot see another
process's writes, and does not make a stale copy current. Guarding with
a lock what two processes change through the store only hides the
conflict until the next save.
