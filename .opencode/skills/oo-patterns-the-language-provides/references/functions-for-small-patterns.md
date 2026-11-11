# Functions for small patterns

Three patterns begin as one operation and no state. This reference turns
each into a function value, uses a clinic example, and names the point
where the class returns.

## A strategy with one operation

A strategy is a choice the caller hands to an object and the object
keeps for its life. The clinic's reminder planner needs one answer:
how long before an appointment the reminder goes. One timing answers a
due time one day before the appointment, another answers a due time two
hours before, and both read the time from the appointment's start.

That timing is a function value. The planner receives a value of type
`(Appointment) -> DateTime`, keeps it, and calls it when a reminder is
due. There is no interface to implement and no class per time. The
staff ask for a reminder a day before; they do not name a timing rule
or discuss one in meetings.

## A command that never leaves its call site

A command is an action captured as an object so it can be passed,
stored or run later. The check-in screen borrows a tablet from the
waiting-room pool. When the screen closes, it releases that tablet, and
the release happens once, on the line that closes the screen. Nobody
queues the release, stores it, logs it, undoes it or retries it.

That action is a function value. It is written where the screen closes,
it uses the tablet the screen holds, and the screen calls it once. No
command class stands between the screen and the release.

## A template step that differs

A template step is one step of a fixed algorithm that the algorithm's
class leaves to a collaborator. A confirmation letter has fixed steps:
the date, the appointment details, the closing. Two ways of printing
the letter, one for the patient and one for the clinician, differ only
in the opening line.

The letter class runs the fixed steps and receives the opening line as
a function value. No base class leaves that line open for a subclass,
and neither printing path copies the fixed steps. The opening line
arrives through the constructor, before the letter writes anything.

## When the class comes back

Each example grows back into a class when its force grows. A timing
that reads the clinic's quiet-hours setting holds state of its own. A
timing that also answers a label and a channel has several operations.
A release that must be queued, stored, undone or retried is a command
object that carries its data. A rule the staff name and discuss, such as the
late-cancellation rule, keeps its class even when it has one operation,
because the name is part of the clinic's language.

The choice is never about what the language can express. It is about
what the object holds, what the callers ask of it, and what the staff
call it.
