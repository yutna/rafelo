# Logs, metrics and traces

Each kind of record answers a different question, and a different person
reads it. Choosing the kind before writing the record keeps it short and
keeps the question it answers in view.

- A log record answers what happened in one request or step: the time,
  the outcome and the identities involved. The person on call reads it
  while following one incident.
- A metric answers how often or how long something happened, over a
  period and across requests. The practice manager reads it without
  looking at any one request.
- A trace answers which calls one request made and where its time went.
  An engineer reading a slow request follows it from the desk to the
  store and back.

## A structured log record

A log record carries named fields, so a reader can search it without
guessing where each value sits in a sentence:

- the time;
- the correlation identifier of the request that caused it;
- the outcome, such as a booking made or refused;
- the identities involved, such as the `PatientId`, the `AppointmentId`
  or the `ClinicianId`;
- the error, when the record reports a failure.

The fields never hold a patient's name, contact details, diagnosis or
notes. A log travels to a search service, to other teams' screens and to
backups that outlive the request, and the people who read it are not the
people who may open the patient's file. An identity lets a reader find
the file through the clinic's own access check; a name or a diagnosis in
the log removes that check.

## Counters and measured durations

A metric counts outcomes or measures how long a step takes. A counter
rises once for each outcome, such as a booking made or a booking
refused, and a duration records how long a step took. Both answer a
question about a population of requests; neither answers why one request
failed.

A metric carries a few label values, such as the site or the kind of
outcome, because each combination of values is a series that the clinic
stores and reads. A patient's identity as a label makes one series per
patient: the number of series grows with the patient list, the metric
costs more to keep, and it now holds a detail about a patient that the
metric did not need. Count by a small group, and find one patient's
requests by the `PatientId` on their log records, then follow each by
its correlation identifier.

## Traces

A trace is the set of calls one request makes, from the desk through the
services it reaches. Each step carries the request's correlation
identifier, so the steps form one path and a step that failed can be
read beside its neighbours. A trace shows where the time went and which
call failed; it holds identities and outcomes, never the patient's
details.

## One refused booking, followed

A receptionist tries to book a slot that is already taken. The desk
answers the refusal, and the request's correlation identifier goes with
it. The practice manager reads the counter of refused bookings and sees
the total rise by one. The person on call searches the logs for the
correlation identifier and finds the request, the slot it asked for and
the refusal it met.

Nobody had to read a patient's name, contact details or notes to follow
the request. The identity on the records is enough to find the file
through the clinic's own access check, for a reader allowed to open it.
