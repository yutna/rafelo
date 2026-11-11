# Refusals and faults

## Booking's refusals under one base

A booking is refused in the clinic's words. `SlotTaken` says the slot is already
held. The module refuses a booking with `ClinicianNotTakingPatients` when the
clinician takes no new patients, and with `BookingLimitReached` when the patient
has reached the booking limit. The module raises all three under one base,
`BookingRefused`. The notation declares `SlotTaken` alone; this skill groups it
under that base, and grouping it takes no error away from the method that
declares it.

A reception screen handles one refusal by its name and the rest by the
base. When `SlotTaken` is raised, the screen offers the next free time.
Any other `BookingRefused` tells the desk to pass the request to the
booking team. A new refusal then needs no edit in the screen until the
desk must treat it differently.

## A port names every refusal

A port lists on its `raises` line each refusal its implementations
raise, by name. The base groups the refusals for a caller that treats
them alike, while the list says which ones a caller may meet. A port
that named only the base would hide the refusals its implementations
raise, and a caller that handles one of them by name would never see it
on the signature it reads.

## A fault is declared once

A fault is a failure no caller can repair: the store does not answer, or an
invariant is found broken. Only the method that raises it itself declares it, as
the notation asks of every `raise`, and the port that method implements declares
it as well. Every method above passes it on undeclared, up to the one handler at
the program's edge. That handler records the fault and answers a general
failure. No layer in between catches it: a catch there either hides the fault,
so nobody records it, or raises it again, and a caller that reads the second
error learns nothing the first did not say.

## Check before the first change

A method that approves a clinician's leave set the request to approved
and only then checked whether the days overlapped a day the clinician is
on call. When they did, it raised `LeaveOverlapsOnCall`, but the request
it refused already said approved, and the next reader of that object saw
leave that nobody had granted. The same method now checks the overlap
first and raises before it changes anything, so a refused request stays
exactly as it was.

## Declared errors in some languages

A language that makes callers declare some errors carries the refusals
as the errors it checks, so each caller handles or declares them, and
the faults as the errors it does not check, so they pass up to the
handler at the edge with no caller above declaring them.
