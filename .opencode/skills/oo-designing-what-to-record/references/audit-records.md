# Audit records

An audit record answers who did what to whose file, and when. It is
domain data, not a log line: the clinic must be able to answer for the
act long after any log has been rotated away.

## What an audit record holds

An audit record holds:

- who acted, such as a `ClinicianId`;
- on whose file, such as a `PatientId`;
- what was done, named in the clinic's words, such as an allergy
  recorded;
- when it happened;
- why, where the clinic asks for a reason, such as a correction.

The use-case object writes the record in the same transaction as the act
it records. Either both are stored or neither is. A record written after
the commit is lost when the commit succeeds and the write fails, and a
record written before the act describes something that may never
happen. The record is stored with the act, as the outbox is stored with
the change that produces the event.

An audit record is kept for as long as the clinic must answer for the
act, which the clinic's own rules decide. It is read by the people who
answer for the act, such as an auditor, and by the patient when the
clinic must show the file. It is never edited and never deleted before
its time: an edited record no longer shows what happened, and a deleted
one leaves the act unanswered. A correction is a new record that names
the record it corrects.

## Not a lifecycle history and not a log

Modeling lifecycles, rule 6, keeps the history of an object's own
transitions as part of its state: an appointment cancelled, a visit
completed. An audit record covers acts that are not a transition of the
object being changed, such as an allergy recorded in a patient's file,
or an access to that file. The two can sit in the same store and are
still read for different questions.

A log record is written for the person on call, may be sampled, rotated
or dropped, and carries no promise that the clinic can answer for an act
later. An audit record is written for the auditor and the patient, is
kept on purpose, and is never sampled.

## Reading a file without changing it

Opening a patient's file changes nothing in it, so the read is a read
and the access is recorded by its own command. The access command is
sent when the access is granted, before the read, and it writes the
audit record; the read that follows still changes nothing, as
separating reads from writes, rule 1, asks. A read that also wrote an
audit record would change the clinic's state, and then no reader could
tell a read from a write.
