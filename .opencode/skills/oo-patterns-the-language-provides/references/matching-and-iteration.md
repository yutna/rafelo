# Matching and iteration

A visitor, an iterator class and a factory all add objects around work
the language can do. This reference weighs each one against the
feature that replaces it, using rooms, a waiting list and the
composition root. It names the point where the class still earns its
place.

## A visitor over kinds of room

A clinic has three kinds of room: a consulting room, a treatment room
and a group room. Two operations cross them: the cleaning minutes a
room needs and the equipment it must hold. A visitor is one object per
operation, and each kind of room accepts it and runs the method for that
kind.

The room kinds stay closed. A new operation is one new visitor with a
method per kind, and the room kinds do not change. That suits a module
whose operations arrive more often than its kinds.

## A closed set with exhaustive matching

The same three kinds form a closed set: one place lists every kind, and
no code outside that place adds another. Each operation is then one
match over the set, naming every kind in its own branch. Exhaustive
matching means the compiler checks that each match handles every case.

When the clinic adds an imaging room, the compiler lists every match
that lacks the new kind, and no match can pass unnoticed. A visitor
pays the same when a kind is added: every visitor gains a method for
it, and the new kind needs an accept method of its own. What the closed
set saves is that machinery: no visitor interface and no accept
methods, while the compiler lists every match to change.

The balance is the side that grows. If new operations arrive more
often, the closed set keeps each change to one match, as replacing
conditionals with polymorphism, rule 7, weighs it. If new kinds arrive
more often, one class per kind behind a small interface keeps a new
kind to one class and one entry where the stored code is read. A
language without the exhaustiveness check loses the compiler's list: a
match that leaves out a kind either falls into a catch-all branch or
fails at run time, and neither reports the missing kind when it is
added.

## Walking a waiting list

A waiting list holds patients in the order they joined and offers
`waiting()` as a read-only view. An iterator is an object with its own
next and has-next messages that walks a collection one item at a time.
A hand-written iterator over the waiting list adds a cursor, and
callers can copy the cursor or send next twice.

The language's own iteration walks the read-only view instead. The list
stays private, callers read the order, and no second cursor has to keep
its place correct. The view shows later changes to the list and still
gives no way to append a patient.

## A factory or the composition root

A container is a tool that builds and wires objects from its own
configuration. It may sit at the composition root where a framework
builds its own objects, and it stays out of domain code, as inverting
dependencies, rules 4 and 5, keep it.

A named factory still earns its place where it decides how a domain
object is born. A factory that refuses an appointment whose earlier
appointment belongs to another patient enforces a valid birth, and
constructing valid objects, rule 4, gives it that job. Moving that
check into a container loses the rule, because the container wires
parts and does not know what makes an appointment valid.

## Following the module's idiom

A module that already works with function values reads naturally when a
new strategy or step is a function value. A module built of classes the
team reads keeps its classes, even when a function value would answer
the same question in a new module. The feature that removes a pattern
in one module is no reason to rewrite another: a reader follows the
module's own shape, not the newest feature in the language.
