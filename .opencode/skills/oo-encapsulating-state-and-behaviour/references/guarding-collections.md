# Guarding collections

- [A read-only view](#a-read-only-view)
- [Methods that name the action](#methods-that-name-the-action)
- [Copy what crosses the boundary](#copy-what-crosses-the-boundary)

A collection held by an object is part of its state. Callers may need to
read it, but reading is not the same as holding the list itself. These
examples use a clinician's working hours and a patient's allergy list.

## A read-only view

A clinic shows a clinician's working hours on several screens. The
screens only read the periods, so `WorkingHours.periods()` returns a
read-only view rather than the list.

```text
value WorkingPeriod
  - day: Weekday
  - opensAt: TimeOfDay
  - closesAt: TimeOfDay
  + new(day: Weekday, opensAt: TimeOfDay, closesAt: TimeOfDay)

class WorkingHours
  - periods: List<WorkingPeriod>
  + new(initialPeriods: List<WorkingPeriod>)
    raises OverlappingHours
    copied := initialPeriods.copy()
    if copied.hasOverlap() then
      raise OverlappingHours
    else
      periods := copied
  + add(period: WorkingPeriod): void
    raises OverlappingHours
    if periods.anyOverlaps(period) then
      raise OverlappingHours
    else
      periods.add(period)
    return
  + periods(): ReadOnlyList<WorkingPeriod>
    return periods.readOnlyView()
```

`copied.hasOverlap()` is taken to mean true when two periods in the
list overlap. `initialPeriods.copy()` is taken to mean a new list with
the same periods, so a caller that later changes its own list does not
change the working hours. `periods.anyOverlaps(period)` is taken to
mean true when some period in the list overlaps the new one.
`periods.add(period)` appends to the working hours' own list once.
`periods.readOnlyView()` returns a `ReadOnlyList<WorkingPeriod>` that
readers cannot change. The constructor raises rather than store an
overlapping list, and it copies first and checks the copy, so a caller
that changes its own list cannot slip past the check. It sets `periods`
before any method reads it, and every field is private.

## Methods that name the action

A patient's allergy list changes when a clinician records an allergy.
`record` checks the list before it adds, and `hasAllergy` answers a
question without changing anything.

```text
class Patient
  - allergies: List<Allergy>
  + new(initialAllergies: List<Allergy>)
    raises AllergyAlreadyRecorded
    copied := initialAllergies.copy()
    if copied.hasDuplicates() then
      raise AllergyAlreadyRecorded
    else
      allergies := copied
  + record(allergy: Allergy): void
    raises AllergyAlreadyRecorded
    if allergies.contains(allergy) then
      raise AllergyAlreadyRecorded
    else
      allergies.add(allergy)
    return
  + hasAllergy(allergy: Allergy): Boolean
    return allergies.contains(allergy)
  + allergies(): ReadOnlyList<Allergy>
    return allergies.readOnlyView()
```

`copied.hasDuplicates()` is taken to mean true when two allergies in
the list are equal. `initialAllergies.copy()` is taken to mean a new
list with the same allergies, so the caller keeps no handle on the
stored list. `allergies.contains(allergy)` is taken to mean true when
the list holds an allergy equal to the new one.
`allergies.add(allergy)` appends once. `record` is a command and
returns nothing; `hasAllergy` and `allergies()` are queries and change
nothing. The constructor raises rather than store a duplicate, and it
copies first and checks the copy, so a caller that changes its own list
cannot slip past the check. It sets `allergies` before either query
reads it, and every field is private.

## Copy what crosses the boundary

A date is mutable in many languages: a caller that keeps the object it
passed in can change the day later. `DayOff` copies both dates in and
both dates out.

```text
value DayOff
  - startsOn: Date
  - endsOn: Date
  + new(start: Date, end: Date)
    startsOn := start.copy()
    endsOn := end.copy()
  + startsOn(): Date
    return startsOn.copy()
  + endsOn(): Date
    return endsOn.copy()
```

`start.copy()` and `end.copy()` are taken to mean new date values with
the same instant. The constructor copies both inputs before it stores
them, and each query returns a copy, so a caller that keeps either date
cannot change the stored value. The fields are private, and the
constructor sets both before either query reads them.

A read-only view is enough for a collection that callers only read. The
caller cannot change it, though it shows the object's later changes, so
it needs no copy. A copy is the safer answer when the caller will keep
the value or change it. Both stop the caller from changing the state
behind the object's back.
