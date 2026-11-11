# Contracts and extension

- [What a method promises](#what-a-method-promises)
- [A subtype that refuses an input](#a-subtype-that-refuses-an-input)
- [Closed and open classes](#closed-and-open-classes)

A contract is what a caller may rely on when it sends a message. Three
parts make it: the requirements the caller must meet, the guarantees the
caller receives, and the invariants that stay true around the call. A
subtype is a substitute only when it keeps all three.

## What a method promises

The notation has no separate block for a contract. A `--` comment under
the signature, after any `raises` line, is where the reader finds it.

```text
class Referral
  -- open for extension: accept may be overridden, keeping its contract
  - patient: PatientId
  - acceptedBy: Clinician?
  + new(patient: PatientId)
    acceptedBy := null
  + accept(clinician: Clinician): void
    raises ReferralAlreadyAccepted
    -- requires: acceptedBy is null
    -- guarantees: acceptedBy is clinician on return
    -- invariant: once set, acceptedBy never changes
    if acceptedBy = null then
      acceptedBy := clinician
    else
      raise ReferralAlreadyAccepted
    return
```

`accept` requires that no clinician has accepted the referral. In return
it guarantees that the clinician it was given is recorded. The invariant
holds in every state: once `acceptedBy` is set, it never changes.
A caller that sends the message when the requirement holds gets
the guarantee; a caller that sends it after an acceptance gets the
declared error. The constructor sets `acceptedBy` to `null`, so a referral
starts with no accepting clinician. Because `accept` is named as
overridable, its three comments are the contract an override must keep.

## A subtype that refuses an input

An urgent referral is still a referral, so a caller may send it anywhere a
referral is expected. Its override must accept every clinician the parent
accepts. This one does not:

```text
class UrgentReferral extends Referral
  + accept(clinician: Clinician): void
    raises ReferralAlreadyAccepted, ClinicianNotOnCall
    -- requires: acceptedBy is null and clinician is on call
    -- guarantees: acceptedBy is clinician on return
    if clinician.onCall() then
      super.accept(clinician)
    else
      raise ClinicianNotOnCall
    return
```

`clinician.onCall()` is taken to answer whether the clinician is on call
now. The override states a requirement the parent never stated, and it
raises an error the parent's contract does not allow. Every caller
written for `Referral` may now fail on an input it was told it could send.
The signature matches and the contract does not.

The fix is one of the two in the last rule of the skill. Widen the
parent's contract so every referral may refuse a clinician who is not on
call, and update every caller that must handle the new error. Or stop
extending `Referral`, hold one instead, and add the on-call rule to the
holder.

## Closed and open classes

The notation has no keyword for a closed class. A fence marks one with a
`--` comment; the language packs name the keyword that writes that mark in
code.

```text
class Appointment
  -- closed: the clinic never subclasses it
  - slot: Slot
  - patient: PatientId
  - status: AppointmentStatus
  - new(slot: Slot, patient: PatientId, status: AppointmentStatus)
  + static book(slot: Slot, patient: PatientId): Appointment
    slot.reserve(patient)
    return new Appointment(slot, patient, Scheduled)
  + static restore(slot: Slot, patient: PatientId,
      status: AppointmentStatus): Appointment
    return new Appointment(slot, patient, status)
  + cancel(reason: CancellationReason): void
    raises AppointmentNotCancellable
    -- requires: status is Scheduled
    -- guarantees: status is Cancelled and the slot holds no patient
    -- invariant: patient never changes
    if status = Scheduled then
      status := Cancelled
      slot.release(patient)
    else
      raise AppointmentNotCancellable
    return
```

A class opened on purpose names the methods a subclass may override, each
with the contract an override keeps:

```text
class ReferralNotice
  -- open for extension: text and deliver may be overridden
  - patient: PatientId
  - notice: String
  - notifier: Notifier
  + new(patient: PatientId, notice: String, notifier: Notifier)
  + send(): void
    -- guarantees: sends text() once, then deliver(message) once
    message := text()
    deliver(message)
    return
  + text(): String
    -- an override keeps: returns the notice text for the patient
    return notice
  + deliver(message: String): void
    -- an override keeps: hands the message to the patient once
    notifier.notify(patient, message)
    return
```

`notifier.notify(patient, message)` is taken to hand the message to the
patient once. `send` asks `text` once and `deliver` once, so one override
of each runs for one send. The comment under `send` writes that promise
down, and a subclass may rely on it. The comments beside the two methods
are the only promises a subclass has to keep. The class stays open
because those promises are written where a subclass author reads them.
