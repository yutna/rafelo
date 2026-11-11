# Factories and builders

- [Named factories](#named-factories)
- [When a builder earns its code](#when-a-builder-earns-its-code)

A constructor is the shortest way to make an object with one shape. A
named factory adds a name when the object has more than one way to
arrive. A builder adds a separate object when most of the parts are
optional. This reference shows the appointment factories from the
skill's pattern and a visit report with many optional sections.

## Named factories

An appointment arrives in two ways: for a patient with no earlier
visit, and as a follow-up to one. Before the factories, a single
constructor with five positions made the caller encode the way in
`null`, `false` and `30`, and nothing stopped a caller from passing a
previous visit that belonged to another patient. `forNewPatient` names
the first way and `followUp` names the second.

```text
class Appointment
  - patient: PatientId
  - slot: Slot
  - previousVisit: Appointment?
  - followUp: Boolean
  - duration: Minutes
  - new(patient: PatientId, slot: Slot, previousVisit: Appointment?,
      followUp: Boolean, duration: Minutes)
  + patient(): PatientId
    return patient
  + static forNewPatient(patient: PatientId, slot: Slot): Appointment
    slot.reserve(patient)
    return new Appointment(patient, slot, null, false, 30)
  + static followUp(patient: PatientId, previous: Appointment,
      slot: Slot): Appointment
    raises NotThisPatientsVisit
    if previous.patient() = patient then
      slot.reserve(patient)
      return new Appointment(patient, slot, previous, true, 30)
    else
      raise NotThisPatientsVisit
```

Both factories reserve the slot once and then create the appointment.
`followUp` reads `previous.patient()` before it reserves anything, so a
refused follow-up leaves the slot untouched. The constructor is private,
and `forNewPatient` and `followUp` are the only methods in the class
that call it, so every appointment is built with all five fields set.

## When a builder earns its code

A visit report has a required patient, visit and clinician, and several
optional sections: a summary, a diagnosis, a prescription and a
follow-up plan. Calling the report's seven-parameter constructor
directly makes a caller count positions and pass `null` for each part
it does not use. The builder keeps the required parts in its own
constructor and adds each optional section through a command that
returns nothing.

```text
class VisitReportBuilder
  - patient: PatientId
  - visit: Visit
  - clinician: ClinicianId
  - summary: String?
  - diagnosis: Diagnosis?
  - prescription: Prescription?
  - followUpPlan: FollowUpPlan?
  + new(patient: PatientId, visit: Visit, clinician: ClinicianId)
    summary := null
    diagnosis := null
    prescription := null
    followUpPlan := null
  + describeVisit(text: String): void
    summary := text
    return
  + recordDiagnosis(finding: Diagnosis): void
    diagnosis := finding
    return
  + prescribe(drug: Prescription): void
    prescription := drug
    return
  + planFollowUp(plan: FollowUpPlan): void
    followUpPlan := plan
    return
  + build(): VisitReport
    raises PrescriptionWithoutDiagnosis
    return new VisitReport(patient, visit, clinician, summary,
      diagnosis, prescription, followUpPlan)

class VisitReport
  - patient: PatientId
  - visit: Visit
  - clinician: ClinicianId
  - summary: String?
  - diagnosis: Diagnosis?
  - prescription: Prescription?
  - followUpPlan: FollowUpPlan?
  + new(patient: PatientId, visit: Visit, clinician: ClinicianId,
      summary: String?, diagnosis: Diagnosis?, drug: Prescription?,
      followUpPlan: FollowUpPlan?)
    raises PrescriptionWithoutDiagnosis
    if drug = null then
      prescription := null
    else
      if diagnosis = null then
        raise PrescriptionWithoutDiagnosis
      else
        prescription := drug
```

The builder's constructor sets `summary`, `diagnosis`, `prescription`
and `followUpPlan` to `null` before any command or `build` reads them.
Each command sets one field once and returns nothing, so the calls do
not chain. `build` passes every part it holds to `VisitReport` in one
call, and the report's constructor holds the rule: it raises
`PrescriptionWithoutDiagnosis` when a prescription has no diagnosis and
sets `prescription` in each other branch. A report made through the
builder or directly is checked in one place, and no caller sends a
setter after it.

A builder for a report with three required parts and four optional
sections earns its code. An object with two fields does not: its
constructor is shorter than the builder, and the builder only adds a
step a caller can forget.
