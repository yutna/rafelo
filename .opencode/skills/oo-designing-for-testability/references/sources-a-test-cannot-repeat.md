# Sources a test cannot repeat

A test repeats only when every value it reads is one it chose. Four
sources escape a test's choice unless the design gives it a place to
stand: the current time, a random draw, a newly generated identifier
and a setting read from the environment. Each reaches the object
through a port, and each port is answered by a stand-in in the test.

- **The current time.** The port is `Clock`, with `now(): DateTime`,
  the shape the inverting dependencies reference gives it. The test's
  stand-in answers the moment the test chose. A clinic example is
  `CheckInstrumentTrays`, which holds a `Clock`; it passes the answer of
  `clock.now()` to `TrayExpiry` as a `DateTime`, and the expiry decides
  from that value whether a sterilised tray is past its shelf life.
- **A random draw.** The port is `RoomDraws`, with
  `nextRoom(): RoomId`. The test's stand-in answers the room it chose,
  so the test knows where a walk-in lands. `WalkInDesk` holds the port
  and asks it once when it places a walk-in visit in a room; the real
  adapter draws from all free rooms.
- **A newly generated identifier.** The port is `VisitNumbers`, with
  `next(): VisitNumber`. The test's stand-in answers the number it
  chose, so the test can find the visit it queued. `WalkInQueue` holds
  the port and gives each queued visit the number it receives.
- **A setting read from the environment.** The port is
  `ClinicSettings`, with `trayShelfLife(): Duration`. The test's
  stand-in answers the shelf life it chose, such as seven days.
  `CheckInstrumentTrays` holds the port and passes the shelf life to
  `TrayExpiry` as a value, so the test knows which trays have expired.

A domain object that needs only a value should receive the value.
`TrayExpiry.hasExpired(tray, now, shelfLife)` takes the time and the
shelf life as parameters, and
[modeling lifecycles](../../oo-modeling-lifecycles/SKILL.md) rule 5
gives the same shape to `recordNoShow(now)`. The use-case object asks
the port once and passes the answer on. The exception is an object that
must ask again while it handles one message, such as a long run that
checks the time between items: it holds the port.
