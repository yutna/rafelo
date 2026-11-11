# Toward and away from a pattern

Rule 5 gives a pattern two directions. This reference walks one clinic
object toward one object per status, and turns a strategy with one
implementation back into a direct construction. Each walk lists its
moves in order, and the tests run after every move.

## Toward one object per status

`ShiftPlan` holds a status, and four methods test it: `canAssign`,
`noticeText`, `canPublish` and `handoverLine`. The status has gained a
case twice in the past year, and a third case arrives when agency shifts
start, so the force is present: the same condition on a status repeats
in several methods and keeps changing. The walk follows [replacing
conditionals with
polymorphism](../../oo-replacing-conditionals-with-polymorphism/SKILL.md)
rule 4.

The moves, in order, are:

1. Run the four tests of `ShiftPlan` and see them pass.
2. Introduce one interface, `ShiftStatus`, with the four messages, and
   one class for the status with the most branches, `PublishedStatus`.
3. Extract the `Published` branch of `canAssign` into a method, move it
   to `PublishedStatus.canAssign`, and let `ShiftPlan` send the message
   when its status is `Published`; run the tests.
4. Repeat step 3 for `noticeText`, `canPublish` and `handoverLine`, one
   method at a time, running the tests after each.
5. Add `DraftStatus` and `SignedOffStatus` the same way, one method at a
   time, running the tests after each.
6. Choose the status object once, where the plan is loaded, and store it
   as the plan's current status; when a command moves the plan to another
   status, replace it with the object for that status; run the tests.
7. Let every method delegate to the current status object, and delete
   the conditionals that tested the status; run the tests.

The force is resolved when every method delegates to the status object
and no method tests the status. Stop there. A status that gates only one
or two methods keeps its check, as [replacing conditionals with
polymorphism](../../oo-replacing-conditionals-with-polymorphism/SKILL.md)
rule 4's exception says.

## Away from a strategy with one implementation

`CancellationDesk` receives a `CancellationPolicy` through its
constructor. The clinic used to have two policies, and the second went
when its plan ended, leaving `StandardCancellation` as the only
implementation. The force has gone: one implementation, no second case
named, and no change that keeps coming back.

The moves, in order, are:

1. Run the tests of `CancellationDesk` and see them pass.
2. Change the type of the desk's field and constructor parameter from
   `CancellationPolicy` to `StandardCancellation`; the composition root
   still builds one `StandardCancellation` and passes it in; run the
   tests.
3. Delete `CancellationPolicy` and the `implements` on
   `StandardCancellation`; run the tests.

The force is resolved when no code names the interface and the one
implementation is built and passed in directly. Stop there, as
[choosing a pattern](../../oo-choosing-a-pattern/SKILL.md) rule 6 asks.
