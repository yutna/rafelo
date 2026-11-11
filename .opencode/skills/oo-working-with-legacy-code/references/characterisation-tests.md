# Characterisation tests

A characterisation test records what old code does, not what it should
do. It is how rule 1 pins a change's surroundings before anything
moves. The test is disposable in design but valuable in effect: it
turns an unknown answer into a fact the next change can be measured
against.

## Choosing inputs from the area the change will touch

Start where the change will land, not where the code is easiest to
drive. If the change adds a column to a monthly summary, pick ledgers
from a month with charges at its first and last day, a ledger with no
charges, and a ledger whose charges were already paid. Those inputs
reach the grouping and the month boundary that the new column will
read.

An old `StatementRun` turns one month's charges into a summary line.
Nobody tested it. The change ahead adds a write-off column, so the
inputs come from the parts of `summaryFor(ledger, month)` that group
`UnpaidCharge` values by patient and by month. A test that only used a
quiet month would cover none of the paths the change alters.

The area the change touches is a reading of the planned edit, not the
whole routine. Covering every path in a large routine is a rewrite's
work, and rule 6 leaves that alone.

## Checking the output the code gives today

Send the chosen input and record the exact answer the routine gives,
including spacing, ordering, rounding and empty lines. A
characterisation test may look odd, because it holds a defect in place
on purpose. That is its job: the next change must not alter the answer
by accident.

If a patient who has paid every charge still appears with a zero line,
record the zero line. If the summary orders patients by an internal
identifier rather than by name, record that order. A tidier answer
belongs in a later change, not in the test that pins today's answer.

Check only what the code answers or what it sends to the places the
test can observe. A characterisation test that reads private fields is
tied to one arrangement of the code, and rule 1 asks for the output,
not the inside.

## Turning a surprise into a note and a later change

A surprising answer is a finding. Write it down in the issue or the
change note with the input that produced it, then leave the answer
alone. Fixing it inside the change that pins the behaviour mixes two
changes: a reader can no longer tell which edit changed the pinned
answer, and the fix has no test of its own.

Rule 1 puts the fix in a separate change after the record exists. That
later change states the answer the clinic wants, and the
characterisation test that recorded the old answer is renamed or
removed when a test for the new answer takes over the same behaviour.

## How many are enough

One input for each path the change could alter is enough in practice.
Count the paths from the planned edit: a branch the new value reaches,
a boundary the new rule reads, an empty collection the new step must
survive. Three or four inputs often cover a small change. A large route
through old code needs more, and a route the change never reaches needs
none.

More inputs than that add cost to every later edit without making the
pin stronger. The test suite for old code is a temporary guard, not a
complete specification.

## Renaming or replacing them later

A characterisation test is named for the input it pins and the answer
it records, such as "a quiet month answers one empty summary line". Once
tests written in the clinic's words cover the same behaviour, the
characterisation test has done its work. Rename it to the rule it now
guards, or delete it if a better test checks the same answer.

Keeping both forever repeats one check and hides which test states the
rule. Removing the old pin when the new test is green is part of the
change, not a later cleanup.
