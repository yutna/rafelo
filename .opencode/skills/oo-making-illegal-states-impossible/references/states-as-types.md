# States as types

A class with flags does not say which combinations are real. Counting
the combinations its fields allow, then counting the states the clinic
has, shows the gap. Closing the set of states and matching over it keeps
the gap from returning when a state is added.

## Counting the combinations

`AppointmentRequest` carries two booleans and one optional reason. Each
boolean allows two values, and the optional reason allows a value or its
absence, so the class allows eight combinations. The clinic has three
states: waiting, accepted and declined. Five of the eight combinations
are states the clinic never has, such as accepted and declined at once,
or a reason with neither.

```text
class AppointmentRequest
  - patient: PatientId
  - clinician: ClinicianId
  - accepted: Boolean
  - declined: Boolean
  - declineReason: String?
  + new(patient: PatientId, clinician: ClinicianId)
    accepted := false
    declined := false
    declineReason := null
  + accept(): void
    accepted := true
    return
  + decline(reason: String): void
    declined := true
    declineReason := reason
    return
```

`false` and `true` are taken to mean the two values a `Boolean` can
hold. The constructor sets all five fields before either action runs,
and each assignment happens once per call. Nothing in the class stops a
second `accept`, or an `accept` after a `decline`.

## A closed set

Behind `RequestState`, one class per state holds only that state's data.
The `--` comment marks the set closed: the interface names every state
the clinic has, and the language packs name the keyword that writes
that mark.

```text
interface RequestState
  -- closed: waiting, accepted and declined are the only states
  + patient(): PatientId
  + clinician(): ClinicianId
```

`WaitingRequest` holds `patient` and `clinician`; `AcceptedRequest`
adds `acceptedBy`; `DeclinedRequest` adds `reason`. `WaitingRequest`
offers `accept` and `decline`, and neither later state offers either.
The accepted state has the clinician who accepted, and the declined
state has its reason, so each state's data is required and no state
carries a field it never uses.

An exhaustive test over the closed set names every state once. With no
catch-all branch, the compiler lists the places a new state must be
handled, so adding a state is a deliberate edit. The language packs show
the syntax; the notation describes the test in prose.

## Enumeration or a class per state

When every state carries the same data, or none, one enumeration says
the set and a class per state adds nothing. `RecallStatus` has three
members, and no member needs a field.

```text
enum RecallStatus
  Due
  Sent
  Closed
```

A notation `enum` holds no data, so its members fit states that carry
none. Behaviour per member belongs to the member where the language
allows it; the notation keeps that behaviour in prose. The states above
are different: `AcceptedRequest` needs `acceptedBy` and
`DeclinedRequest` needs `reason`, so a single enum member would carry a
field the others lack. That is the signal to give each state a class.
