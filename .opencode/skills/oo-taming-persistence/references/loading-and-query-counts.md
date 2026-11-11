# Loading and query counts

A mapper chooses when to read: with the aggregate, on first touch, by
identity through a repository, or as a read query for a list. Each
choice costs a different number of queries and fails in a different
place. This reference compares them, counts a clinician's day sheet,
shows a test that keeps the count flat as the list grows, and explains
why a lazy reference cannot survive the session that loaded it.

## The loading choices

|Choice|Cost|Where it fails|
|---|---|---|
|With the aggregate|one query|it reads more than the use case needs|
|On first touch|one query per touch|a list runs one per item|
|By identity|one query per aggregate|a list runs one per item|
|A read query|one query|it cannot be used to make a change|

The first choice loads an association with the aggregate that holds it,
so the use case has everything it needs after one read. The second is
lazy loading: the mapper reads the association when a caller first
touches it. The third follows the identity reference of designing
aggregates, rule 3, where one aggregate holds another's identity and
loads it through that aggregate's own repository. The fourth is the
read query that layering the system, rule 6, lets a read with no
decision take.

## A clinician's day sheet

A day sheet for one clinician lists thirty appointments and shows the
patient's name on every line. With lazy loading, the sheet runs one
query for the day's appointments and then one more for each
appointment's patient: one plus thirty. The same sheet as one read
query returns the thirty rows with the patient's name already in them,
so it runs one query. When the list grows to sixty, the first count
becomes sixty-one and the second stays one.

## A test that counts queries

A test can count the queries the store receives while one use case runs.
Run the use case over thirty appointments and record the count, then run
it over sixty and assert that the count is the same. A count that stays
flat as the list grows shows that the list is filled by one read query;
a count that grows with the list shows a query per row. The test runs
against the mapping tool and a real store, because the in-memory store
of designing repositories checks the rules but runs no query.

## A lazy reference after the session closes

A screen that touches an association after the request's session has
closed asks the mapper for data with no session to read it. The mapper
either fails or opens a session of its own, outside the transaction the
use case opened, and either answer is wrong for the screen. The
identity reference of designing aggregates, rule 3, removes the lazy
reference: the appointment holds the patient's identity, the use case
loads the patient through its own repository while the session is open,
and the screen receives a value the use case already read.
