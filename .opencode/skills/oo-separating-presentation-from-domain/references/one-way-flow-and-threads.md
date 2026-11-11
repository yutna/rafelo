# One-way flow and threads

A screen works by one loop: the user does something, the view reports
the intent, the presentation object changes the state it owns, and the
view redraws from that state. The loop keeps the domain on one side and
the screen on the other, and it holds when the result arrives late or
on another thread.

## The loop on a booking screen

On the booking screen of the pattern, the receptionist chooses a slot
and then a patient. Each choice is an intent, and the view sends it to
`BookingPresenter`. The presenter stores the choice, decides from the
choices it holds whether the button may be enabled, and tells
`BookingView` what to show. The view changes its button and nothing
else. When a step needs a rule from the clinic, the presenter asks a use
case; no step in the loop reaches a domain object.

A toolkit's two-way binding is a convenience between the view and its
presentation object: what the user types goes one way, and a changed
value comes back the other. Point the same binding at a domain object
and the toolkit writes each keystroke into it, past the rules its
methods keep, so a half-typed value reaches an object the store may
save. The loop replaces that binding with intent going in and state
coming out. The binding between the view and the presenter may still
run both ways; what it must not do is reach past the presenter into the
domain.

## A slow lookup off the user-interface thread

A receptionist types a health number, and the screen needs the patient
looked up in the regional patient register. The presenter asks a use case
for the lookup, and the use case sends the register's port, declared
beside the domain. One adapter at the edge keeps the register's client
and maps its reply into the clinic's values. The call may take a second
or more.

Start the lookup on a background task, not on the user-interface thread,
and give it a reply that returns to that thread. The reply updates the
presentation object on the thread that owns the screen, and the view
redraws from the new state. Two failures follow when that order is
broken. A lookup made on the user-interface thread blocks the toolkit's
event loop, so the screen stops repainting and ignores the user until
the call returns: it freezes. A background task that updates a widget
directly writes the screen from a thread that does not own it, and the
toolkit fails at random, with a corrupted redraw or an error that no
test reproduces.

## A reply the user has moved on from

The receptionist types a second health number before the first lookup
returns. The first reply is now stale. If it arrives last and writes the
screen's state, the screen shows the earlier patient under the later
number, and the receptionist books against the wrong person. The
presentation object records the lookup it last started and checks each
reply against that record; a reply for an older lookup changes nothing.
The test starts two lookups, answers them out of order, and checks that
only the later one reaches the state.

## When the user interface is functions of state

A module whose user interface is components that are functions of their
state keeps that idiom and does not adopt these classes. The loop still
holds. A component renders the state it is given and passes each event
up to the object that owns the state and the screen logic; a test calls
that object without rendering anything. A slow lookup runs off the
user-interface thread, its result returns to that thread, and the same
last-request check drops a stale reply. What changes is the shape of the
presentation object, not the separation.
