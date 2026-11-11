# Core and generic parts

Not every part of the clinic's work deserves the same design effort. The
core is what makes this clinic different, a supporting part is needed but
does not set the clinic apart, and a generic part is already done well
elsewhere. A part earns a rich model when doing it better than other
clinics matters to patients or to the business; everything else is kept
plain, moved out of the core, or bought. Sorting the work is a judgement,
and the sort changes as the clinic changes.

## One clinic's work, sorted

- The core is how the clinic fits urgent patients into clinicians'
  days. The rule that decides which clinician can take an urgent patient
  now, and what gives way when nobody can, is the work this clinic does
  differently. It earns a rich model, the strongest developers and the
  most tests.
- Reserving a meeting room is supporting. The clinic needs it, but every
  clinic needs the same thing and no patient chooses this clinic for it.
  A plain model, or a script over a calendar, is enough.
- Payroll and sending mail are generic. Products and services already do
  them well, and building either would teach the team nothing about the
  clinic's own work. The clinic buys them or uses them as a service.

## Where each kind gets its effort

The core gets the model with the clinic's own words, the rules that
change often, and the people who can keep it small. A supporting part
gets a plain model, named for what it does, with no attempt to make it
general. A generic part gets a bought product or a service behind a
port, so the core names what it needs and the product keeps its own
model. Buying a product for a supporting part is also fine when the
clinic will never compete on it.

## A core statement

The team writes one short statement with the clinic's staff, in words
the staff use, and keeps it where the team plans work. For example:

> We fit urgent patients into the clinicians' days faster and more
> safely than any other clinic in the region.

The statement is not a mission slogan. It names the part of the work the
clinic chooses to be good at, so the team can hold a proposal against it.
A request that improves how urgent patients are placed belongs in the
core. A request to build a better mail sender does not; it gets a
product behind a port. The staff say whether the statement still matches
the work, and the team revises it when the clinic's work changes.

## Moving a generic part out

Sending messages to patients is a common part to move. The core context keeps
the rule that says when a message must go out and what it must say. It sends the
message through `Notices`, the port the aggregates skill's reference already
uses, and the generic context, or the product, answers that port. The core then
holds one interface and no address book, no delivery schedule and no provider's
model. The move has a cost: one more boundary and one more translator or
adapter to keep. Do it when the generic part changes for its own reasons, such
as a new provider or a new channel, and leave it in the core when it never
varies.

## When to merge two contexts back

Two contexts are better merged when one team owns both, the same release
carries their changes, and every word keeps one meaning across them. The
translation then buys nothing and costs a boundary. Merge them, and note
the decision so the next team does not redraw the line without evidence.
