# Changing a contract

A contract with another system has two sides. A reply leaves the clinic
and an old reader on the other side reads it. A request arrives and an
old writer on the other side sends it. The same change can break one
side and leave the other working, so judge every change twice.

## Which changes break which side

The table reads each change against the two sides. "Yes" means an old
reader or writer written against the previous version fails; "No" means
it keeps working.

|Change|Breaks old readers of a reply|Breaks old writers of a request|
|---|---|---|
|Add an optional field|No|No|
|Add a required field|No|Yes|
|Remove a field|Yes|No|
|Rename a field|Yes|Yes|
|Change a field's type|Yes|Yes|
|Change a field's meaning|Yes|Yes|
|Add an allowed value|Yes|No|
|Tighten a check|No|Yes|
|Loosen a check|Yes|No|

The "No" cell for a removed field on the writer side rests on tolerant
reading: the clinic ignores the field the old writer still sends. A
clinic that fails on an unknown field turns that cell into a "Yes",
which is why rule 4 asks for tolerant reading before it allows a
compatible change.

## Reading tolerantly

A tolerant reader takes the fields it knows from a reply and ignores
the rest. It does not fail because a field it never heard of appeared,
so the clinic can add an optional field without a new version. The same
habit applies to a request the clinic reads: unknown fields are
ignored, not refused.

The limit is the field the clinic relies on. Tolerant reading is not a
reason to accept a missing family name or an unreadable date; the
mapping refuses it, as rule 2 says, and the refusal names the field.
Ignoring what is unknown and refusing what is missing are two
different jobs.

## Naming and serving a version

A version can sit where its readers can see it: in the address of the
endpoint, in a header of the request or the reply, or in a field of the
message itself. Pick one place and keep it there for the life of the
version, so a reader can tell which contract it is speaking.

Two versions can run at once. Each version gets its own transfer types
and its own mapper, and both mappers read the one domain model. The old
mapper keeps answering the old shape until its readers have moved, and
the new mapper answers the new shape. No domain class learns which
version a caller used, and a fix to a rule reaches both versions in one
change.

## Tests that record what each reader expects

A reader's expectations can be written down as a contract test: the
fields the reader reads, the values it accepts, and the error it
expects when one is missing. The clinic runs those recorded
expectations against every build of the contract, so a change that
would break that reader fails before release. This is a
consumer-driven contract: the reader drives the test, and the publisher
keeps it green.

Each reader keeps its own file of expectations, and the contract's
tests run all of them. A new version adds a new set, and the old set
stays until that reader has moved. A test written from the publisher's
own assumptions proves only that the publisher agrees with itself.

## Stored messages and events

A stored message is a contract with code that has not run yet. A queued
message, an outbox event, a cached document or an exported file written
today is read by a later version of the code. The reader is future
code and the writer is today's code, so the table above still applies.

Two ways keep that promise. The later code can still read the old
shape, which means the shape may change only in ways the old reader
survives. Or a planned migration converts the stored data: read the
old shape, write the new one, keep both readable while the migration
runs, and check that every stored item was converted. A migration that
reports no count of what it converted has not shown that it finished.

An outbox event is the clearest case, because the transaction stores it
now and a relay sends it later, perhaps after the code has been
deployed again. The event's stored shape is the contract the relay and
every handler read, so a field removed from it is a field removed from
data already waiting to be sent.
