# Transition tables

- [The table](#the-table)
- [The methods](#the-methods)
- [Reading the table for gaps](#reading-the-table-for-gaps)
- [One test per row](#one-test-per-row)

A lifecycle is easier to argue about in a table than in code. The table
names the states, the moves out of each, the event that causes each
move, and the error a refused move raises. Write it with the people who
know the business, then give each row its method.

## The table

A clinic takes a request for a home visit. The request starts as
`Requested`; a coordinator finds a clinician and schedules it; the
clinician marks it `Done` after the visit, or either side declines it
before then. `Done` and `Declined` end the life of a request.

|State|Leaves by|Cause|A refusal raises|
|---|---|---|---|
|Requested|schedule|a clinician takes the request|`HomeVisitNotSchedulable`|
|Requested|decline|a clinician or patient declines|`HomeVisitNotDeclinable`|
|Scheduled|complete|the clinician ends the visit|`HomeVisitNotCompletable`|
|Scheduled|decline|a clinician or patient declines|`HomeVisitNotDeclinable`|
|Done|nothing|the visit happened|the error of the move asked|
|Declined|nothing|the request ended|the error of the move asked|

## The methods

Each row with a move becomes a method named for that move. `decline`
has two source states, so its method nests the `if` steps: each step
tests one source state, and each call runs one step.

```text
enum HomeVisitStatus
  Requested
  Scheduled
  Done
  Declined

class HomeVisit
  - patient: PatientId
  - address: Address
  - status: HomeVisitStatus
  - declineReason: CancellationReason?
  - new(patient: PatientId, address: Address,
      status: HomeVisitStatus)
    declineReason := null
  + static request(patient: PatientId, address: Address): HomeVisit
    return new HomeVisit(patient, address, Requested)
  + schedule(): void
    raises HomeVisitNotSchedulable
    if status = Requested then
      status := Scheduled
    else
      raise HomeVisitNotSchedulable
    return
  + complete(): void
    raises HomeVisitNotCompletable
    if status = Scheduled then
      status := Done
    else
      raise HomeVisitNotCompletable
    return
  + decline(reason: CancellationReason): void
    raises HomeVisitNotDeclinable
    if status = Requested then
      recordDecline(reason)
    else
      if status = Scheduled then
        recordDecline(reason)
      else
        raise HomeVisitNotDeclinable
    return
  - recordDecline(reason: CancellationReason): void
    status := Declined
    declineReason := reason
    return
  + declineReason(): CancellationReason?
    return declineReason
```

`new HomeVisit(...)` builds a request with `patient`, `address` and
`status` set, and with no decline reason yet; `request` is its only
public factory, and the constructor is private. `CancellationReason` is
the notation's reason for a cancellation, and a declined home visit
uses the same value to say why. `Address` is the value a visit is sent
to. `declineReason()` answers the reason after a decline, and null
before one. `schedule`, `complete` and `decline` each change the status
once. `decline` reaches `recordDecline` from either source state, and
each call runs exactly one branch, so `status` and `declineReason` are
assigned once per call. `recordDecline` is private, so no caller skips
the checks.

## Reading the table for gaps

Read the table before writing the methods, and ask three questions.

- Does every state that is not final have a way out? `Scheduled` with
  neither `complete` nor `decline` would hold a request forever. `Done`
  and `Declined` are final, so their empty row is the decision, not a
  gap.
- Does every transition have a cause? A move nothing in the business
  triggers is code nobody asked for. The cause column is where a review
  notices that a state changes on its own.
- Does every refusal have a name? A move that fails with no error of
  its own leaves a caller unable to tell which rule refused it. Name
  the error after the refused transition, as the table does, and raise
  it in the method that performs the move.

## One test per row

Write one test for each row of the table. A test starts a visit in the
row's source state, sends the move, and checks the status it reaches.
For a refusal, it starts the visit in the row's state, sends a move the
row does not list, and checks the error. A row with no test is a rule
nobody has checked; a new row without its test is a move nobody will
notice breaking.
