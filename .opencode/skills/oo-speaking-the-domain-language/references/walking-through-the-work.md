# Walking through the work

A walkthrough follows the work as the clinic does it, not as the code
happens to be organized. It gives every step a past-tense event, a
request, a person and a rule, and from those it draws the names the
code should carry.

## A clinic day, event by event

The timeline below follows one patient from check-in to discharge.
Reception and the nurses speak in turn; each line records the event in
the past tense, the request behind it, who makes it, the rule that can
refuse it and the name it becomes in the code.

1. *Patient checked in.* The request is "check this patient in", made
   by reception. The rule refuses a patient who is not booked for today
   or whose appointment is no longer scheduled. The code name is
   `Appointment.checkIn`.
2. *Visit started.* The request is "start this visit", made by the
   nurse. The rule refuses a visit before the patient has checked in,
   or when no clinician is assigned. The code name is `Visit.start`.
3. *Observation recorded.* The request is "record this observation",
   made by the nurse. The rule refuses an observation on a visit that
   is already closed, and requires a value. The code names are
   `Visit.record(observation)` and the type `Observation`.
4. *Recall booked.* The request is "book this patient's recall", made
   by the nurse. The rule refuses booking a recall that already has an
   appointment, raising `RecallAlreadyBooked`. The code names are
   `Recall` and `Recall.book(appointmentId)`.
5. *Appointment missed.* The request is "record that this patient did
   not come", made by reception. The rule refuses a record before the
   slot has ended and for an appointment that was checked in. The code
   name is `Appointment.recordNoShow`.
6. *Patient discharged.* The request is "discharge this patient", made
   by the nurse. The rule refuses a discharge while an observation is
   still waiting. The code name is `Visit.discharge`.

Read the list back in the staff's words. A step with no name on the
right is a gap: either the code has no concept for it, or the concept
exists under a word nobody says out loud. Both are worth fixing before
the next change touches the step.

## The questions that find a missing concept

The words often arrive when someone asks about an edge of the work.

- "What do you call it when ...?" asks for the noun. If the answer is a
  phrase the staff use every day, it is a candidate class or value.
- "What happens if ...?" asks for the rule and the refusal. An answer
  that describes a decision is a candidate method or check.
- "Who decides that?" asks for the object that owns the rule. A
  decision with no owner is a concept without a home.
- "Which word would you use on the phone?" separates the word the staff
  say from the word a form or a manual uses.
- "When is it too late to ...?" asks for the state that makes a request
  invalid, and often names a state the code already has.

Ask the question, write the answer in the staff's words, and only then
choose the code name. A name chosen first tends to describe the code's
mechanism, and the staff's word is lost.

## When a walkthrough is worth the time

A walkthrough pays off when the process is new, disputed or spread
across teams that do not share a name for it. It also pays off when a
wrong name has already cost a change, or when nobody can say which step
owns a rule. Bring the people who do the work, not only the people who
write the code, and keep one timeline that everyone can point at.

For a small change, the staff's own forms, letters, screens and
messages already hold the words. Read them before calling a meeting. If
the change touches one step and its name is not in dispute, use the
word the form uses and leave the rest of the timeline alone. Stop when
every step on the timeline has a name the staff accept and a rule the
code can refuse; a walkthrough that keeps going turns into a map of the
whole clinic.
