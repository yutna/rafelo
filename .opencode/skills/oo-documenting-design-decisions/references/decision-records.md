# Decision Records

A decision record keeps the reason for a choice that is costly to
reverse, as rule 1 asks, in the shape rule 2 gives it. This file lists
the parts of a record, shows one worked record, and shows how a later
record supersedes it, as rule 3 asks.

## The parts of a record

- **Number and title.** The next free number, and the choice as a short
  sentence, such as "Keep clinical photographs in a file store".
- **Date.** The day the record was accepted.
- **Status.** Proposed, accepted, or superseded by a named record.
- **Context.** The forces as they stood on that day: what the clinic
  needed, what limited the choice, and what was already in place.
- **Options weighed.** Each option the team considered, with what spoke
  for it and against it.
- **Choice.** The option taken, in one or two sentences.
- **Consequences.** What follows from the choice, the costs included,
  and what the team must now keep true.

A record stays short: a reader finishes it in a few minutes. It lives
in the repository, in one folder of numbered files, beside the code it
shapes.

## A worked record

This is the record that the Pattern's one-line comment points to.

- **Number and title.** 12. Keep clinical photographs in a file store.
- **Date.** 2026-03-12.
- **Status.** Accepted.
- **Context.** Clinicians photograph a patient's skin condition at each
  visit, to compare it at the next one. The photographs were rows in
  the clinic database, and the nightly backup now runs into the
  morning. Every photograph must stay linked to the visit it was taken
  at.
- **Options weighed.** Keep the rows and buy a faster backup: the
  database keeps growing. Send the photographs to the imaging
  supplier's archive: it keeps no link to the visit. Write each
  photograph to a file store under its own identifier, and keep only
  the identifier in the database: two stores must then stay in step.
- **Choice.** Write each photograph to the file store under its
  identifier; the visit's row keeps the identifier.
- **Consequences.** The database backup is small again. A photograph is
  written to the file store before the row that names it is stored, so
  a row never names a missing file. A photograph whose row was never
  stored is found and removed by a weekly check.

The record ends in a state that keeps rule 2: beside the choice, it
holds the context, the options and the consequences.

## Superseding a record

When the clinic later moves the photographs to a new archive that keeps
the link to the visit, record 12 is not edited. Record 19 is written
with its own context, options and choice, and says that it supersedes
record 12. Record 12 changes in one line only: its status becomes
"Superseded by record 19". Its context and options stay as they were,
so a reader still sees why the file store was right in its day, and the
two records end linked both ways, as rule 3 asks.
