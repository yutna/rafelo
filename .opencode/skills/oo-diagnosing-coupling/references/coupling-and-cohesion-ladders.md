# Coupling and cohesion ladders

- [Coupling ladder](#coupling-ladder)
- [Cohesion ladder](#cohesion-ladder)
- [Instability on three clinic modules](#instability-on-three-clinic-modules)

The two ladders label a design from opposite sides. Coupling asks how
tightly two parts are tied; cohesion asks how well one part holds
together. Read a ladder as a set of names for what you see, not as a
scoreboard.

## Coupling ladder

The rungs run tightest first: content, common, external, control, stamp,
data. Name the rung a tie sits on and use it as a diagnostic label. It
is not a score, and a lower rung is not automatically the next refactor.

1. **Content.** One module reaches into another's internals. A report
   reads `Invoice`'s private fields instead of asking it for a total.
   Loosen it by asking the owner for the answer.
2. **Common.** Two modules share global data. Booking and billing both
   read one global insurer table. Loosen it by passing the value each
   needs, or by giving the table one owner with a message.
3. **External.** Two parts must match an outside format or protocol.
   The claim export and its test fixture both spell the insurer's fixed
   layout. Loosen it by wrapping the format in one adapter that the rest
   of the clinic does not see.
4. **Control.** A flag steers the callee's logic. A call
   `send(appointment, urgent)` makes the sender choose a different path.
   Loosen it by giving each path its own message or its own object.
5. **Stamp.** A whole structure is passed where a part is needed. A
   call `invoice(visit)` takes every visit field to read the insurer and
   the date. Loosen it by passing the two values, or a small value
   object that holds them.
6. **Data.** Only the values needed cross the boundary. A call
   `total(amount, discount)` takes two `Money` values and nothing else.
   This is the loosest rung, and still a tie: the two sides agree on the
   meaning of each value.

## Cohesion ladder

The rungs run weakest first: coincidental, logical, temporal,
procedural, communicational, sequential, functional. A class held
together only by kind of thing or by timing is a candidate to split. A
class low on the list is usually doing one job.

1. **Coincidental.** The parts have no theme. `ClinicUtilities` holds a
   date formatter, a file reader and a tax constant. Split it and give
   each part a home.
2. **Logical.** The parts group by kind of thing. `Report` holds
   appointment reports, invoice reports and reminder reports, chosen by
   a mode flag. Split by the kind, or move each report to its own class.
3. **Temporal.** The parts group by when they run. `MorningTasks` opens
   the clinic, prints the roster and sends reminders. Split it; the
   clock is not a reason to share a class.
4. **Procedural.** The parts group by a shared sequence. `CheckIn`
   identifies the patient, checks the referral and creates the
   appointment in order. Move the steps behind messages, or keep the
   flow in one use-case object that delegates the work.
5. **Communicational.** The parts work on the same data. `InvoiceRun`
   totals, taxes and prints the same set of visits. A class like this is
   often acceptable; split only when the parts change for different
   reasons.
6. **Sequential.** One part's output feeds the next. `ClaimRun` builds
   a claim and then submits what it built. Keep the sequence if it is
   one task, and let each step own its result.
7. **Functional.** Every part serves one task. `SlotReservation`
   reserves or releases a slot for one patient. This is the strongest
   cohesion; leave it alone.

## Instability on three clinic modules

Afferent coupling counts the modules that depend on this one. Efferent
coupling counts the modules this one depends on. Instability is
`efferent / (afferent + efferent)`: 0 means stable, 1 means unstable.
The three modules below form one small graph: billing depends
on booking, booking depends on reminders, and reminders depends on
nothing.

|Module|Afferent|Efferent|Instability|
|---|---|---|---|
|Billing|0|1|1 / (0 + 1) = 1.0|
|Booking|1|1|1 / (1 + 1) = 0.5|
|Reminders|1|0|0 / (1 + 0) = 0.0|

Read the direction: billing (1.0) depends on booking (0.5), which
depends on reminders (0.0). Each dependency points toward a more stable
module. Reminders is depended on by booking and depends on nothing, so
it is the stable end. Billing is a leaf with no dependants, so its high
instability is expected, not a defect. These counts are places to look,
not targets.
