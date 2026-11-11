---
name: oo-encapsulating-what-varies
description: Use when one requirement keeps changing, when adding a case means editing working code, or when deciding how flexible a design should be.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Encapsulating What Varies

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A requirement that changes twice is showing where the design should
bend. This skill finds that point from evidence, hides it behind an
interface the rest of the code can trust, and keeps the seam as small
as the cases that justified it. It also says when to leave a single
case alone.

## When to use

- The same requirement has changed more than once, and the next change
  is already visible in the work.
- Adding a case means editing code that already works, such as another
  branch in a chain of conditions.
- The team is deciding how flexible a design should be before the next
  case arrives.
- Two parts of a module change at different rates or for different
  reasons.
- A review asks whether an interface or an extension point is worth
  building now.

## When not to use

- The change is a one-line fix inside one method. Change the body and
  stop.
- There is one case and neither the history nor the plan names a
  second one. Build it directly.
- What varies is data, such as a list of values a clinic configures,
  not behaviour. Keep it as data.
- A seam already exists and the new case fits it. Add the adapter and
  leave the seam alone.

## Core rules

1. Rule. **Find the point of variation from evidence.** Read what the
   version history shows changing and ask the business what it says
   will change next. Hide that point behind a stable interface, so the
   rest of the code does not move when it does.

2. Rule. **Add a case by adding a class or an entry, not by editing
   tested code.** Open for extension and closed for modification applies
   where variation is real: the new case supplies its own details, and
   the callers keep their code.

3. Default. **Separate parts that change at different rates or for
   different reasons.** Put them in different modules and keep the
   volatile details at the edges, where the outside formats and
   protocols live.

   The exception is a small part whose stable rule and volatile detail
   always change in the same request. Splitting it would make every
   change cross a boundary for no gain, so keep it together until the
   changes pull apart.

4. Judgement. **Build no seam for a variation that has neither
   appeared nor been named by the business with a reason.** One case is
   built directly. The second or third real case shows the axis and
   justifies the seam. That is a judgement about the evidence, not a
   counting rule.

5. Judgement. **Prefer a little duplication to a seam on an axis the
   evidence has not confirmed.** A seam on the wrong axis makes the
   real change harder: duplication is visible and can be removed,
   while a wrong seam spreads through every caller.

## Pattern

Before, three classes, `ResultsScreen`, `VisitSummary` and
`LabFollowUp`, call `LabResultsClient` directly. The client builds one
lab's URL and reads its status codes. A second lab has signed and starts
next month. Each lab is an outside system with its own URL format and
status codes, so the lab is the axis that varies, and without a seam
each caller would have to choose a client.

Before:

```text
enum LabStatus
  Pending
  Ready
  Rejected

class LabResultsClient
  - http: LabHttp
  - baseUrl: String
  + new(http: LabHttp, baseUrl: String)
  + fetch(order: LabOrder): LabReport
    -- builds this lab's URL and reads its status codes
    response := http.get(baseUrl, order.number())
    if response.status = 200 then
      return new LabReport(order, Ready)
    else
      if response.status = 409 then
        return new LabReport(order, Rejected)
      else
        return new LabReport(order, Pending)

class ResultsScreen
  - lab: LabResultsClient
  + new(lab: LabResultsClient)
  + show(order: LabOrder): LabReport
    return lab.fetch(order)

class VisitSummary
  - lab: LabResultsClient
  + new(lab: LabResultsClient)
  + summary(order: LabOrder): LabReport
    return lab.fetch(order)

class LabFollowUp
  - lab: LabResultsClient
  + new(lab: LabResultsClient)
  + followUp(order: LabOrder): LabReport
    return lab.fetch(order)
```

After, the callers ask a `LabResults` for `resultsFor(order)`. Each lab
keeps its URL format and status codes in its own adapter, and the three
classes depend only on the interface. The interface is a protected
variation around the part that is about to change: a new lab is a new
adapter, not an edit to the callers.

After:

```text
enum LabStatus
  Pending
  Ready
  Rejected

interface LabResults
  + resultsFor(order: LabOrder): LabReport

class CityLabResults implements LabResults
  - http: LabHttp
  - baseUrl: String
  + new(http: LabHttp, baseUrl: String)
  + resultsFor(order: LabOrder): LabReport
    response := http.get(baseUrl, order.number())
    if response.status = 200 then
      return new LabReport(order, Ready)
    else
      if response.status = 409 then
        return new LabReport(order, Rejected)
      else
        return new LabReport(order, Pending)

class RegionalLabResults implements LabResults
  - http: LabHttp
  - baseUrl: String
  + new(http: LabHttp, baseUrl: String)
  + resultsFor(order: LabOrder): LabReport
    response := http.get(baseUrl, order.number())
    if response.status = 201 then
      return new LabReport(order, Ready)
    else
      if response.status = 409 then
        return new LabReport(order, Rejected)
      else
        return new LabReport(order, Pending)

class ResultsScreen
  - results: LabResults
  + new(results: LabResults)
  + show(order: LabOrder): LabReport
    return results.resultsFor(order)

class VisitSummary
  - results: LabResults
  + new(results: LabResults)
  + summary(order: LabOrder): LabReport
    return results.resultsFor(order)

class LabFollowUp
  - results: LabResults
  + new(results: LabResults)
  + followUp(order: LabOrder): LabReport
    return results.resultsFor(order)
```

In both fences `http` and `baseUrl` are private and the constructor sets
them before `fetch` or `resultsFor` reads them. The callers hold one
field, `lab` or `results`, and no caller reads a lab's URL or status
codes. Each method reaches the network once, and every branch returns a
`LabReport`. `CityLabResults` maps the status codes exactly as
`LabResultsClient` did, so moving the code changed no lab's behaviour.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- One function that most recent changes edit for the same kind of
  request.
- A growing chain of conditions on a kind, a provider or a channel.
- An interface with exactly one implementation and no second one
  planned.
- Configuration options for variations nobody uses.
- A caller that names a concrete lab or format in its own code.

## Common mistakes

- Building an abstraction on the first case.
- Choosing the axis of variation by guess instead of evidence.
- Hiding a variation behind a vague, general name.
- Reading open-closed as never editing existing code.
- Letting the first adapter's URL and status codes shape the
  interface.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes the task and defines the
  rule labels.
- [oo-diagnosing-coupling](../oo-diagnosing-coupling/SKILL.md) names
  the tie a seam is meant to loosen and weighs whether it does.

## Further reading

- [Finding the seam](references/finding-the-seam.md)
