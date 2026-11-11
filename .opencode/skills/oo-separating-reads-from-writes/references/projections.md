# Projections

Reception's board shows the day's appointments with their status. In the
Pattern, `TodayBoard` runs one query joining appointments, patients,
clinicians and rooms each time it refreshes, against the tables booking
writes. A projection keeps read rows shaped for that board instead, and
`TodayBoard` reads only those rows.

## Building the board

A projection can start empty and be built from scratch in either of two
ways. It can read the write store, take each appointment that falls on a
day and add its row. Or it can replay the stored events where they are
kept, as they are for an event-sourced aggregate, applying each in
order. The outbox is not the store to replay from: it holds an
event until a relay has sent it, then marks it sent, so a clinic that
wants a replay keeps its events somewhere that outlives the outbox.

Once built, the projection stays current through one handler for each
event that changes its rows. A booking adds the appointment's row to its
day. A cancellation marks that appointment's row cancelled. The handler
that frees the slot changes no board row, because the board shows
appointments and not free slots. The board's projection holds its own
`HandledEvents`, and the handler records each event's identity there, so
a second delivery of the same event changes nothing.

Beside the rows, the board says when it was last brought up to date, as
the moment the projection handled its latest event, not the event's own
time: a shipped `AppointmentCancelled` carries no time. A reader can
then tell that a cancellation made after that moment has not reached the
board yet, instead of reading a row that is behind as a row that is
wrong.

## Rebuilding the board

When the board's row shape changes, the projection is rebuilt into new
rows while the old rows keep serving the screen. The new rows replace
them once the rebuild has finished, so the screen never shows a
half-built board. The rebuild starts from the write store or the stored
events, never from the old rows.

Nothing but the projection writes the read rows. A screen, a report and
a hand edit are all outside it, and a correction made there is lost at
the next rebuild while the write side stays wrong. A wrong figure is
fixed by fixing the write side or the handler, then rebuilding.

The projection can keep its rows in the clinic's own database while they
are few and the read load is light. A second store for the reads earns
its cost when a search must cross free text the write store cannot
search, or when the read load must not reach the write store at all.
Then the projection writes to that store, and the cost of running it and
keeping it current is weighed against what the reads gain.
