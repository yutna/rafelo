# Subtypes or a closed set

- [The two axes](#the-two-axes)
- [Reading the version history](#reading-the-version-history)
- [A closed set of cases](#a-closed-set-of-cases)

A case set grows on one of two sides, and the shape that keeps the next
change small depends on which side grows. This reference names the two
sides, shows how the version history answers the question, and describes
a closed set whose every case one test must cover.

## The two axes

The kinds are the cases themselves. The visit kinds of the Pattern are
an example: consultation, procedure and vaccination are three kinds. The
operations are the messages every kind answers: `prepare` and
`canBookOnline` are two.

|A change|One subtype per case|A closed set|
|---|---|---|
|A new kind|One new class|Every exhaustive test|
|A new operation|Every class|One exhaustive test|

With one subtype per case, a new kind is one new class, and the one
place that maps a stored code gains one entry. No operation class moves.
A new operation is a method on the interface, and every class that
implements it answers the method, so the new operation edits every
class. With a closed set, a new operation is one test that names every
case, and a new kind edits every such test. When the set is closed and
the test names its cases, the compiler can list each test that no longer
covers the set.

## Reading the version history

Read the changes that touched the case set over the last few releases.
For each change, write down whether it added a kind or an operation. A
change that added a fourth kind is one mark on the kinds side; a change
that added a message every kind answers is one mark on the operations
side. The side with more marks is the side the code should expect next.

Ask the business about the next few months as well, and count only a case
that has a name and a reason. A kind that is merely possible does not tip
the balance. Pick the shape for the side that grows: subtypes when kinds
grow, a closed set when operations grow.

## A closed set of cases

The Pattern's Before already names a closed set: the enum `VisitKind`
with `Consultation`, `Procedure` and `Vaccination`. In a closed set, one
type lists every case, and no code outside the type adds one. A test
over the set names each case in its own branch and leaves no catch-all
branch. The notation writes such a test as a chain of
`if ... then ... else`, so a reader checks by eye that every case appears
and that the last branch is a case, not a catch-all.

A language whose compiler checks the set lists every test that misses a
case after a member is added; the language packs show the syntax for
that check. The pack's notation has no such check, so its closed set
relies on the reader and on a test at the boundary that fails when an
unknown case arrives.

For the visit kinds, adding a kind such as a home visit is cheap with
subtypes, because it is one new class and one entry where the stored
code is read. Adding an operation such as a printable summary is cheap
with a closed set, because it is one test over the set. If the clinic
has added two operations this year and no kind, the closed set keeps the
next change small. If it has added two kinds and no operation, subtypes
do.
