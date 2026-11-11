# Identity and units of work

A store session does two jobs that a domain object never sees: it
answers one object for one identity, and it decides when the objects it
tracked are written. This reference shows both jobs in one reception use
case, then says what goes wrong when the session outlives the request
and when a module is better served by an active record.

## One appointment reached twice

A reception use case moves an appointment to a new time, and first
checks the clinician's other appointments that day, because the move
must not put two appointments in one slot. It reaches the appointment
twice: once by its identity, through `Appointments.find`, and once in
the list that `forClinicianOn` answers for that clinician and day. The
second reach decides the move, so it needs the whole appointments
rather than a read of a few fields.

Without an identity map, each read builds its own appointment from the
same row. The use case changes the appointment it found by identity,
and the list's copy still holds the old slot. If the use case saves the
list's copy, the first change is lost; if it saves both, the second
save overwrites the first. Either way one change disappears without an
error.

With an identity map, the session keeps the object it built for that
identity and answers it again when the list reaches the same
appointment. Both paths hold one object, the move happens once, and one
save stores it. What is stored is the appointment under its
`AppointmentId`, in the clinic's database, in the transaction the use
case opened.

## A unit of work's life

A unit of work is opened with the transaction, at the start of the use
case. As the use case loads aggregates, the unit of work records each
object under its identity and notes which of them changed. At commit it
writes those changes in one transaction, and then the use case discards
it; the next request opens a new one.

A unit of work kept across requests answers objects from an earlier
read. Another user may have changed the row since, so the session hands
back a stale appointment. A change made for one request can also be
written when a later request commits, although nobody meant to save it.
The session grows as well, because it holds every object every request
loaded.

## Tracking or an explicit save

Rule 5 of designing repositories chooses between a repository that
tracks the aggregates it handed out and writes their changes when the
transaction ends, and one with an explicit `save` that the caller sends
after each change. What differs is who names what is written: under
tracking the session finds every changed object it tracks, while under
an explicit save the caller names each aggregate. Either way the writes
commit when the application service ends the transaction. One use case
must not mix the two, because a forgotten save then means two things:
under tracking the change is written anyway, and under an explicit save
it is lost. The identity map serves either choice: it only answers objects, and
has no say in when their changes are written.

## When an active record is still plainer

Not every module earns a mapper. A clinic module that reserves meeting
rooms has a few independent rules and classes that mirror their tables:
a room, a reservation, a recurring hold. An active record gives each
class its own row and its own save, and the module reads in one place. A
mapper would add a stored record and an adapter for each class and move
the same fields twice. Choose the mapper when a class's fields or rules
part from its table, as rule 1 of [taming persistence](../SKILL.md)
says; until then, the active record is less code.
