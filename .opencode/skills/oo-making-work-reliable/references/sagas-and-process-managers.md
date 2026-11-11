# Sagas and process managers

A process that spans several aggregates or systems cannot hold one
transaction over all of them. Each step commits on its own, and a later
failure is repaired by undoing the steps already done. This reference
follows one clinic process and the two ways to coordinate it.

## A process in steps

Booking a procedure is one process with four steps. The desk books the
procedure, takes the deposit, reserves the room the procedure needs,
and confirms the appointment to the patient. Each step changes one
aggregate or one outside system, and each commits before the next
starts. Between two steps the clinic is in a state the staff can see:
the procedure is booked and its deposit taken, while its room is not
yet reserved.

The steps do not share one transaction, as rule 4 of
[designing aggregates](../../oo-designing-aggregates/SKILL.md) asks. A
transaction over the appointment, the deposit and the room would hold a
lock across systems that cannot share one, and a failure at the last
step would roll back work the patient has already been told about. The
process accepts that the steps are visible apart, and repairs what a
later failure leaves behind.

## Compensating steps

Each step that a later failure must undo has a compensating step:
cancelling the appointment, refunding the deposit, and releasing the
reserved room. A compensating step undoes the effect of its step, not
its history: the appointment's record shows that it was made and then
cancelled, and the patient's statement shows the charge and its refund.

A compensating step must itself be safe to repeat. The process may crash
after the step runs and before its result is recorded, so the same
compensation can run twice. Before it acts, the step checks whether the
process has already run it, as a handler checks for an event it has
handled in rule 5 of [publishing domain
events](../../oo-publishing-domain-events/SKILL.md). The release or the
cancel it sends is not safe to repeat on its own: a second release would
free a room that another procedure has reserved since, and a second
cancel is refused, because `Appointment.cancel` raises
`AppointmentNotCancellable` for an appointment no longer scheduled. A
refund carries an identity of its own, created once with the step, so a
second refund with that identity answers with the first refund instead
of paying the money again.

## Steps joined by events

A short chain of steps that never branches can be joined by domain
events. The handler of the appointment's event starts the deposit step;
the handler of the deposit's event reserves the room; the handler of
the room's event confirms to the patient. Each handler reacts to the
step before it and runs after that step commits, in a transaction of
its own, as
[publishing domain events](../../oo-publishing-domain-events/SKILL.md)
asks.

The chain stays short and straight: one event, one handler, one next
step. When a handler must choose between two next steps, or wait for a
person, the chain has outgrown events.

## A process manager

A process that branches, waits for a person or must show staff where it
stands is run by a process manager: an object stored like an aggregate,
with its own identity and its own state, which reacts to each step's
event and sends the next command. Its state names the step it has
reached, such as deposit taken or room reserved, and the step it waits
on.

The process manager is stored in the clinic's store under its identity,
in the transaction that records its own state change, so a crash never
loses where the process stands. It is not a domain object: it
coordinates steps across aggregates and systems and holds no rule of
any one of them.

## A step that waits for a person

The clinic's procedure needs a clinician's approval before its room is
reserved. The process manager records that it is waiting for approval
and shows that state to the staff. When the clinician approves, the
approval command reaches the process manager, which sends the command
to reserve the room. If the clinician refuses, the process manager
sends the compensating steps for the deposit and the appointment.

What the staff see is the process manager's state, not a guess from
several tables. A screen lists the processes waiting for approval, with
the patient, the procedure and the step the process reached.

## Why no transaction spans the steps

A saga never holds one transaction across its steps, as rule 4 of
[designing aggregates](../../oo-designing-aggregates/SKILL.md) asks.
One aggregate changes in one transaction, and a rule across two
aggregates is brought true by a later step after the commit. The saga's
later steps are those later steps, and its compensating steps repair
the ones that a failure leaves behind. What the patient is told at each
point says what has happened, not what the whole process will do.
