# Monitors and active objects

## A monitor object for the check-in count

`CheckInCount` is a monitor object: it holds the number of patients
checked in today and one lock. Its `checkIn(patient: PatientId)` method
takes the lock, reads the number, adds one, stores the new number and
releases the lock. Its `count()` method takes the same lock and answers
the number. Because one method holds the lock for the whole check and
change, two check-ins cannot both read the same number, and neither
change is lost.

The race comes back when a caller reads the count in one message and
writes the new number in another. Two threads read three, each adds one
outside the lock, and both write four. One check-in disappears. The
object must offer the one message that does the whole job, as rule 5 of
[the skill](../SKILL.md) asks, and no caller may compose the change from
a read and a write.

A monitor suits a short check and change. A method that waits for
another system under the same lock makes every caller wait for that
system, and the lock is held for the whole wait.

## An active object for notes to an outside lab

The clinic sends notes to an outside laboratory, and a call to the
laboratory can take seconds. A request thread that waits for it holds a
lock too long, so a `LabNoteSender` active object owns the work. It holds
a queue built for threads and runs one task of its own. A request puts a
note on the queue and receives a reply it collects later; the owner task
takes the next note, sends it, and completes the reply with the
laboratory's answer or its refusal.

No request thread waits while a note is on its way, and the notes leave
in the order the queue gives them. The request that needs the answer
waits for the reply, not for the lock. The active object is the choice
of rule 6 of [the skill](../SKILL.md) when the work is slow and callers
can collect an answer later.

## Two monitors that call each other

One monitor object holds the check-in count and another holds the count of rooms
in use. If the first calls the second while holding its own lock, and the second
calls the first while holding its own lock, each waits for the lock the other
holds. Neither method ever finishes, and both objects stop answering.

The rule that prevents this is the one in rule 6 of
[the skill](../SKILL.md): never call another system or another locked
object while holding a monitor's lock. A method that needs an answer
from the other object takes the value it needs, releases the lock, and
then calls out. When the work cannot be split that way, an active object
takes it off the caller's thread, so no caller waits behind it.

## The screen's thread as an owner

Rule 6 of
[separating presentation from domain](../../oo-separating-presentation-from-domain/SKILL.md)
gives the screen's state to the toolkit's user-interface thread. A slow
use case runs off that thread, and its result comes back to it to update
the presentation object's state.

That thread is an owner like any other. The presentation object's state
is read and written only on it, and a background task that wants to
change that state hands the change over rather than writing the state
itself. Which thread may touch a screen is decided there, not by this
skill.
