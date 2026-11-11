---
name: oo-working-with-legacy-code
description: Use when changing software that has no tests, when an old class must change before it can be tested, or replacing an old system piece by piece.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Working with Legacy Code

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Old code that no test covers answers the question "what does this do?"
with uncertainty. A change reaches a method nobody understands, a
constructor wants a database before the object exists, and a static call
leaves no place to put a stand-in. This skill makes the smallest safe
path through that code: pin what it does today, break one dependency at
a time with edits that move no logic, add the new rule as new code a
test can hold, and, when a whole part must go, move one capability at a
time behind the interface its callers already use. The old code changes
only where the task needs it.

## When to use

- A class or routine must change and nothing tests the area the change
  touches.
- A constructor does work a test cannot repeat, so a test cannot build
  the class.
- Code reaches an outside system through a static call, and a test has
  no place to put a stand-in.
- A new rule belongs in the middle of a long method that no test covers.
- A large old part must be replaced while its callers keep working.
- You are deciding what to leave alone in old code.

## When not to use

- Tests already cover the code and would catch a change in behaviour:
  that is
  [refactoring toward object design](../oo-refactoring-toward-object-design/SKILL.md).
- The code is new and its design is still open: that is
  [designing for testability](../oo-designing-for-testability/SKILL.md).
- The question is which antipattern in the old code to treat first:
  that is
  [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md).
- The old part is a separate system another team owns, and the question
  is how two models talk: that is
  [bounding contexts](../oo-bounding-contexts/SKILL.md).

## Core rules

1. Rule. **Before changing code that has no tests, record what it does
   today with characterisation tests: feed it inputs from the area the
   change will touch and check the output it gives now, even when that
   output looks wrong.** When an input shows a likely bug, write it
   down and fix it in a separate change after the record is in place,
   so the change you came for alters nothing else.

2. Rule. **Until tests cover a class, change its dependencies only
   through small, mechanical edits that leave every caller seeing the
   same behaviour.** Three such edits are: take a collaborator as a
   constructor argument instead of building it inside; pull an
   interface the class owns out of a concrete class it uses; put a
   static call behind a method on an object the class receives. None of
   them moves logic, and each is checked by reading the change,
   building the program and running the tests that exist. Where every
   caller cannot change in the same edit, keep the old construction
   path in one named factory that passes the real collaborator: it
   holds a break that already existed in one place, adds none, and goes
   once every caller builds the class at the composition root, as
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rule 3 asks.

3. Rule. **Get a class under test through a seam: an interface the
   class owns, with its collaborator passed in through the constructor,
   so a test hands it a stand-in and never edits the class again.**
   This is the shape
   [inverting dependencies](../oo-inverting-dependencies/SKILL.md)
   rules 1 and 2 give new code; old code reaches it one dependency at a
   time, starting with the one the change needs.

4. Default. **Add new behaviour as new code, written test first, that
   the old code calls: grow a new class that holds the logic, or wrap
   the old class in a new one that answers the same interface and runs
   the new step before or after it.** The old code gains only the call
   into the new code and the use of its answer, or nothing at all when
   the wrapper takes its place; the rule itself lives in the new code.

   The exception is old code that tests already cover where the change
   lands: change it in place.

5. Judgement. **Replace a large old part one piece at a time behind the
   interface its callers already use, rather than rewriting it whole:
   send one capability at a time to new code, keep the old part working
   for the rest, and delete each old piece once nothing reaches it.** A
   rewrite in one go loses behaviour that nobody wrote down. What tips
   the balance is whether old and new can run side by side: when the
   new part speaks another model, a translating layer comes first, as
   [bounding contexts](../oo-bounding-contexts/SKILL.md) rule 4 places
   one.

6. Default. **Change only what the task needs, plus the seams and
   tests that make that change safe, and leave the rest of the old code
   alone until a change reaches it, as
   [recognising antipatterns](../oo-recognising-antipatterns/SKILL.md)
   rule 5 leaves a stable part alone.**

   The exception is old code that the change history shows most coming
   changes will pass through: pin it, then improve it in refactoring
   steps of their own.

## Pattern

Before, `ReorderRun` is old code with no tests. Its long `run`, left
out of the fence, sends `orderItem` for each item it finds below its
level, and `orderItem` sends `supplier.order(item)` once. The clinic now
needs a new rule: a controlled drug is reordered only with a
pharmacist's approval. Editing that rule into `run` would change code
no test covers.

Before:

```text
class ReorderRun
  - supplier: Supplier
  + new(supplier: Supplier)
  + orderItem(item: StockItem): void
    supplier.order(item)

interface Supplier
  + order(item: StockItem): void
```

Before the edit, characterisation tests pin what `orderItem` and the
run around it do today (rule 1), and the fences leave those tests out.
After, `Supplier` is unchanged, and a new check guards the send.

After:

```text
interface Supplier
  + order(item: StockItem): void

interface OrderApprovals
  + hasApproval(item: StockItem): Boolean

class ControlledItemCheck
  - approvals: OrderApprovals
  + new(approvals: OrderApprovals)
  + mayOrder(item: StockItem): Boolean
    if item.isControlled() then
      return approvals.hasApproval(item)
    else
      return true

class ReorderRun
  - supplier: Supplier
  - check: ControlledItemCheck
  + new(supplier: Supplier, check: ControlledItemCheck)
  + orderItem(item: StockItem): void
    if check.mayOrder(item) then
      supplier.order(item)
    return
```

`ControlledItemCheck` is new and written test first: the test builds it
with a stand-in for `OrderApprovals` and one controlled and one ordinary
item, sends `mayOrder` for both, and checks that the controlled item
follows the stand-in's answer while the ordinary item answers `true`
(rule 4). `ReorderRun` gains one field, one constructor parameter and
the one call whose answer guards the send, while the rule about
controlled items lives in `ControlledItemCheck` (rules 2 and 4); the one
place that builds `ReorderRun` at start-up now also builds the check.
`StockItem.isControlled()` is taken to answer whether the item is a
controlled drug, and `Supplier.order` is taken to send one order to the
supplier. `true` is the Boolean value. A controlled item without
approval is left for the run's other steps, which the fence leaves out.
The fences store nothing in the clinic's database. In each version,
`orderItem` sends at most one order for one call.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A change to code with no tests, and no characterisation test written
  first.
- A constructor that reads a file or opens a connection, so no test can
  build the class.
- A static call to an outside system from many places.
- New logic edited into the middle of a long untested method.
- A bug fixed in the same change that pins the behaviour.
- A rewrite planned in one go, with the old part switched off on one
  day.

## Common mistakes

- Writing tests for what the code should do before pinning what it does.
- Cleaning up untested code beyond what the change needs.
- Moving logic while breaking a dependency, before any test covers it.
- Keeping the named factory after every caller can pass the
  collaborator.
- Replacing the old part's interface while moving its pieces, so
  callers change twice.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-testing-object-oriented-code](../oo-testing-object-oriented-code/SKILL.md)
  writes and names the tests that replace the pin once the rule is
  clear.
- [oo-designing-for-testability](../oo-designing-for-testability/SKILL.md)
  shapes a seam in new code so a test can choose its collaborators.
- [oo-refactoring-toward-object-design](../oo-refactoring-toward-object-design/SKILL.md)
  takes the tidy-up steps once tests cover the code a change touches.
- [oo-inverting-dependencies](../oo-inverting-dependencies/SKILL.md)
  puts a port beside the domain and builds the graph at the composition
  root, which rules 2 and 3 rely on.
- [oo-bounding-contexts](../oo-bounding-contexts/SKILL.md) places a
  translating layer where two models meet, which rule 5 uses.
- [oo-recognising-antipatterns](../oo-recognising-antipatterns/SKILL.md)
  finds the old part that changes most, which rule 6 uses to order the
  work.

## Further reading

- [Characterisation tests](references/characterisation-tests.md)
- [Breaking dependencies](references/breaking-dependencies.md)
- [Replacing an old part piece by piece](references/replacing-an-old-part-piece-by-piece.md)
