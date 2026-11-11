# Replacing an old part piece by piece

This route is the pattern the index calls Strangler Fig. It replaces a
large old part while its callers keep working, by moving one capability
at a time to new code behind the messages those callers already send.

## Route one capability at a time

The old patient index answers three capabilities: searching for a
patient, registering a new one, and merging duplicate records. Its
callers send the same messages before and after the replacement, so the
interface stays still and both sides share one patient store throughout.

Build the new search piece beside the old index. The characterisation
tests for search, written as rule 1 asks, run against the old index and
record the answers it gives. Run the same tests against the new piece
before any caller switches, so both answers are compared while both
pieces can run. Then move one caller at a time to the new search. The
old index still answers search until the last caller has moved, and it
still answers registering and merging throughout.

When search has moved, take registering the same way. Build the new
registration piece, run the pin against both sides, move the callers,
and leave the old registration in place until nothing reaches it. Merge
duplicates is last, because it reads records that registration creates
and because its rules are the least understood.

One capability at a time keeps the working system whole. If a new piece
disagrees with the pin, only that capability is in question; the other
two keep running through code that has not changed.

## Run the pin against both sides

The tests from rule 1 are the comparison, not a formality. Run them
against the old piece and record its answers. Run the same tests against
the new piece before its first caller switches. A disagreement means
the new piece is not ready, or the pin missed a case the change reaches;
settle it while both pieces are still available.

Keep the pin green on the old side for as long as any caller still
reaches it. When the last caller moves, the pin runs against the new
piece alone, and the old answers are history rather than a second
specification.

## Delete each old piece once nothing reaches it

Deleting is part of the route, not a later cleanup. Once a search, a
registration or a merge has no caller on the old side, delete that
piece and the data it alone used. A piece kept "just in case" is read by
every newcomer and changed by every later edit, and it hides whether the
route is finished.

The old index disappears when its last capability has moved. What
remains is the new code behind the same caller-facing messages, plus the
tests that recorded what the old part did.

## When a translating layer comes first

A new part does not always speak the old part's model. A new patient
store may name a patient by a different identity, or call a merge
something the clinic has no word for. Putting new code straight behind
the old messages would then make every caller translate.

In that case, place a translating layer at the boundary first, as rule 5
says and as bounding contexts, rule 4, places one. The layer turns the
old messages into the new model's terms, and the capabilities move
behind it one at a time.
