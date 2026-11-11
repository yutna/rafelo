---
name: oo-deciding-object-or-data
description: Use when deciding if something should be a class or just data, when classes are only getters and setters, or when shaping DTOs and records.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Deciding Object or Data

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

Some parts of a clinic program are objects that keep rules and protect
them. Others are data: a configuration, opening hours a clinic defines,
or a payload another system sends. This skill tells the two apart by
where the rules live, so a class is added when it owns a rule and not
only to make a design look object-oriented.

## When to use

- A class has only getters and setters and someone calls it an anemic
  model.
- A new type could be a class, a record, a map or a data transfer
  object.
- An API response or opening hours a clinic defines are being modelled
  in the domain.
- A business rule sits in a service that reads another class's fields.
- A record or data transfer object has started to grow behaviour.
- A design mixes data at the edge with objects in the core, and the
  conversion needs a home.

## When not to use

- The class already owns its rules and the question is which method
  belongs where. That is assigning responsibilities.
- The code is a script or a data pipeline with no business rule to
  protect. Leave the data and its functions in their own idiom.
- The question is whether two values are equal or whether one has
  identity. That is modeling values and entities.

## Core rules

1. Rule. **An anemic model is a defect when a business rule has no
   home.** A service or controller that reads another object's data and
   decides with it keeps the rule away from the data it reads, so both
   drift apart. The defect is the homeless rule, not the absence of
   methods: a class with no methods is fine when no rule belongs to it.

2. Rule. **Keep plain data plain when its shape comes from outside the
   code.** Configuration, fields a user or tenant defines, and message
   formats another system owns arrive with their shape already decided.
   A class per screen, form or tenant adds mapping and a second place to
   change, and the problem did not ask for that complexity.

3. Rule. **A data transfer object carries data across a process or
   layer boundary and holds no business rules.** Convert it into a
   domain object once, at the edge. The core then speaks its own types,
   and a change to the wire format stops at the converter.

4. Default. **When a type is only data with value equality, use the
   language's record or value type.** Add behaviour only when a rule
   needs it, and let the record carry the data until then.

   The exception is a value whose construction must reject an
   impossible state, such as a time range whose end must come after its
   start. Give that type a constructor that enforces the rule, and it
   becomes a value object with a reason to exist.

5. Rule. **Let a domain object earn its place by protecting an
   invariant or owning a rule.** The test is direct: which rule would
   break if this were a plain map? If no rule breaks, the map is
   enough. If one does, the object is the rule's home, and the rule
   should move there.

6. Judgement. **Expect a mixed design: plain data at the edges, objects
   with rules at the core, and one conversion between them.** A design
   that is all data has no home for its rules. A design that wraps every
   edge shape in an object pays for behaviour nobody uses. The
   conversion is the seam between the two; keep it in one place.

## Pattern

Before, the booking API returns the `Appointment` domain object as JSON
to the mobile app. The app parses the field names, so renaming
`startsAt` breaks it. An `isLate` flag that only the appointment screen
needs has also become a field of `Appointment`.

Before:

```text
enum AppointmentStatus
  Scheduled
  Cancelled

class Appointment
  + patient: PatientId
  + startsAt: DateTime
  + status: AppointmentStatus
  + isLate: Boolean
  + new(patient: PatientId, startsAt: DateTime, isLate: Boolean)
    status := Scheduled
  + cancel(): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
    else
      raise AppointmentNotCancellable
    return

class BookingApi
  - appointments: AppointmentRepository
  + new(appointments: AppointmentRepository)
  + appointment(id: AppointmentId): Appointment
    return appointments.find(id)
```

After, `BookingApi` builds an `AppointmentView` record at the edge from
the `Appointment`. The view is only data: it holds no rule, and the
mobile app can depend on its field names. `Appointment` keeps `cancel`
and no longer stores the screen's flag.

After:

```text
enum AppointmentStatus
  Scheduled
  Cancelled

class Appointment
  - patient: PatientId
  - startsAt: DateTime
  - status: AppointmentStatus
  + new(patient: PatientId, startsAt: DateTime)
    status := Scheduled
  + patient(): PatientId
    return patient
  + startsAt(): DateTime
    return startsAt
  + cancel(): void
    raises AppointmentNotCancellable
    if status = Scheduled then
      status := Cancelled
    else
      raise AppointmentNotCancellable
    return

value AppointmentView
  - patient: PatientId
  - startsAt: DateTime
  - isLate: Boolean
  + new(patient: PatientId, startsAt: DateTime, isLate: Boolean)

class BookingApi
  - appointments: AppointmentRepository
  - clock: Clock
  + new(appointments: AppointmentRepository, clock: Clock)
  + appointment(id: AppointmentId): AppointmentView
    appointment := appointments.find(id)
    startsAt := appointment.startsAt()
    late := startsAt.isBefore(clock.now())
    return new AppointmentView(appointment.patient(), startsAt, late)
```

The view copies three values. `BookingApi` asks the appointment for its
start and compares it with the clock before it builds the view. The
appointment's fields are private, so `cancel` is the only place that
changes `status`, and no field is read before its constructor sets it.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- Services full of conditions on another class's fields, with one
  service per data class.
- A class per configuration screen, or a class per form a tenant
  defines.
- Data transfer objects that validate business rules or carry business
  methods.
- Domain objects serialised straight into API responses.
- A generic map passed through the core where a rule needs a type.

## Common mistakes

- Adding methods to every data class so the design looks
  object-oriented.
- Calling every data transfer object anemic when it has no rule to
  hold.
- Letting data transfer object types leak into the domain core.
- Modelling user-defined or tenant-defined fields as fixed classes.
- Keeping a real rule in a map-based shape because the shape is data.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes the task and defines the
  rule labels.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  decides which class owns a rule once the question is ownership.
- [oo-modeling-values-and-entities](../oo-modeling-values-and-entities/SKILL.md)

## Further reading

- [Data at the boundary](references/data-at-the-boundary.md)
