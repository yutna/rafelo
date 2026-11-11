# State and strategy

- [The conditionals](#the-conditionals)
- [The status objects](#the-status-objects)
- [What the order gained](#what-the-order-gained)
- [A strategy passed in once](#a-strategy-passed-in-once)

A lab order allows a small set of actions, and its status decides which
actions it allows. This reference rebuilds that condition as one object
per status, then contrasts that state with a strategy chosen from
outside.

## The conditionals

`LabOrder` holds a status, a specimen and a report text. Its three
commands each start with the same test on the status, so the rule is
written three times and a new status edits all three.

Before:

```text
enum LabStatus
  Pending
  Collected
  Cancelled

class LabOrder
  - status: LabStatus
  - specimen: Specimen?
  - reportText: String?
  + new()
    status := Pending
    specimen := null
    reportText := null
  + collect(sample: Specimen): void
    raises OrderNotCollectable
    if status = Pending then
      status := Collected
      specimen := sample
    else
      if status = Collected then
        raise OrderNotCollectable
      else
        raise OrderNotCollectable
    return
  + cancel(): void
    raises OrderNotCancellable
    if status = Pending then
      status := Cancelled
    else
      if status = Collected then
        raise OrderNotCancellable
      else
        raise OrderNotCancellable
    return
  + report(text: String): void
    raises OrderNotCollected
    if status = Collected then
      reportText := text
    else
      if status = Pending then
        raise OrderNotCollected
      else
        raise OrderNotCollected
    return
```

`new()` is taken to build an order with all three fields set before any
command reads them. `collect` stores the specimen once and changes the
status once. `cancel` changes the status once. `report` stores the text
once. Each command tests `status` in the same shape, and the last two
branches of each chain have the same body, which is the copy this
reference removes.

## The status objects

After, `LabStatus` is an interface with one query per action. Each query
answers the status the order moves to, and raises when the action is not
allowed for that status. The status objects hold no fields and change
nothing.

After:

```text
interface LabStatus
  + afterCollect(): LabStatus
    raises OrderNotCollectable
  + afterCancel(): LabStatus
    raises OrderNotCancellable
  + afterReport(): LabStatus
    raises OrderNotCollected

class Pending implements LabStatus
  + new()
  + afterCollect(): LabStatus
    return new Collected()
  + afterCancel(): LabStatus
    return new Cancelled()
  + afterReport(): LabStatus
    raises OrderNotCollected
    raise OrderNotCollected

class Collected implements LabStatus
  + new()
  + afterCollect(): LabStatus
    raises OrderNotCollectable
    raise OrderNotCollectable
  + afterCancel(): LabStatus
    raises OrderNotCancellable
    raise OrderNotCancellable
  + afterReport(): LabStatus
    return new Collected()

class Cancelled implements LabStatus
  + new()
  + afterCollect(): LabStatus
    raises OrderNotCollectable
    raise OrderNotCollectable
  + afterCancel(): LabStatus
    raises OrderNotCancellable
    raise OrderNotCancellable
  + afterReport(): LabStatus
    raises OrderNotCollected
    raise OrderNotCollected

class LabOrder
  - status: LabStatus
  - specimen: Specimen?
  - reportText: String?
  + new()
    status := new Pending()
    specimen := null
    reportText := null
  + collect(sample: Specimen): void
    raises OrderNotCollectable
    status := status.afterCollect()
    specimen := sample
    return
  + cancel(): void
    raises OrderNotCancellable
    status := status.afterCancel()
    return
  + report(text: String): void
    raises OrderNotCollected
    status := status.afterReport()
    reportText := text
    return
```

`new Pending()`, `new Collected()` and `new Cancelled()` are taken to
build the status object for that case, and the status classes hold no
fields. Each status object answers the next status as a query. `LabOrder`
assigns that answer to its own `status` field, so the status object never
changes the order and the design needs no reference back to it. The
order's commands change the state and return nothing; the status queries
return an answer and change nothing. That keeps rule 4 of
`oo-encapsulating-state-and-behaviour` without a special case. A refused
command raises before the order assigns a new status or records its data,
so a refused collect leaves both `status` and `specimen` as they were.

## What the order gained

The order now holds no condition on status: every command sends one
query. A new status is a new class that answers the three queries, and a
status that moves into it returns it from one query. The status classes
are small because they hold no fields: each answer is a construction or
a raise. When a status needs data of its own, give it a field and set
that field in its constructor before a query reads it.

## A strategy passed in once

`LabReport` needs a format. The caller chooses the format and passes it
through the constructor once; the report sends every result to that same
format for its whole life. That is a strategy: the choice comes from
outside and stays fixed. A status is the opposite: the order's own
actions choose the next one, and the order replaces it. When a format
must change with the order's status, it is not a strategy but part of
the status behaviour. When the clinic chooses one format per report and
never changes it, it is a strategy.

```text
interface ReportFormat
  + format(result: LabResult): String

class PlainFormat implements ReportFormat
  + format(result: LabResult): String
    return result.summary()

class CodedFormat implements ReportFormat
  + format(result: LabResult): String
    return result.code()

class LabReport
  - format: ReportFormat
  - result: LabResult
  + new(format: ReportFormat, result: LabResult)
  + render(): String
    return format.format(result)
```

`result.summary()` is taken to return the result's plain text and
`result.code()` its short code. `LabReport` sets both fields in its
constructor before `render` reads them, and `render` sends one message to
the format. The format never changes, so every render of one report uses
the format the caller chose.
