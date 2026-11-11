# Absence

## Four answers for a missing value

A method that finds nothing has four answers. They differ in what the
caller must learn.

- **Raise.** Where the value must exist and its absence is an error,
  raise an error named for what is missing. A check-in screen looks up
  the appointment it names, and that appointment must exist: when it is
  gone the lookup raises `AppointmentNotFound` and the screen stops with
  a message.
- **Declare `Type?`.** Where each caller decides for itself what
  absence means, say in the result that the value may be absent. A
  patient's preferred clinician is answered as `ClinicianId?`, because
  the reminder job skips the preference while the booking screen asks
  the patient to choose one.
- **Answer a special case.** Where every caller would do the same with
  the absent case, return an object of the same type that gives that
  case's answer. A lab request that needs no fasting is answered by a
  `NoFasting` instruction that tells the patient to eat as usual, so the
  request screen prints it like any other.
- **Answer a null object.** A null object is the special case whose
  answer is to do nothing. A site with no arrival kiosk is answered by a
  `NoArrivalKiosk` that accepts every check-in message and does nothing,
  because no caller must be told that the site has no kiosk.

## A null object keeps every promise

A null object stands only where doing nothing keeps every promise of its
type. The substitutability skill's `ReminderChannel` promises to deliver
the reminder or hand it on. A channel that drops reminders without a
word breaks that promise, so it is not a null object for the type
however empty its body looks.

## An empty list is enough

When the answer is a collection, an empty list says that there is none,
and no special case is needed. "No appointments today" is an empty list
of appointments, which every caller can walk without a check. A special
case object would add a second way to say the same thing.
