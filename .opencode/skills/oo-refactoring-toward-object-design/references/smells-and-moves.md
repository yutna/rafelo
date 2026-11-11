# Smells and moves

Rule 4 names six smells and the moves that treat each one. A smell is a
place to look; the moves below are the order to take once a change makes
the smell worth treating, and the tests run after each move as rule 3
asks.

- **A method that lives off another object's data.** `TriageAssessment`
  has an `urgency(vitalsChart)` method that reads the chart's
  temperature, pulse and oxygen saturation, and reads none of
  `TriageAssessment`'s own fields, so the decision and its data sit in
  different objects. The moves, in order, are: move `urgency` to
  `VitalsChart` as `urgency()`, then inline the forwarding method on
  `TriageAssessment` so its callers send the chart. The decision then
  sits on the object whose data it uses, which is [limiting what an
  object knows](../../oo-limiting-what-an-object-knows/SKILL.md) rule 5.

- **A primitive that carries a domain rule.** `BoosterPlan` holds the
  days between two doses as a plain number, and both
  `BoosterPlan.nextDue()` and `BoosterCard.print()` check that the
  number lies within the vaccine's shortest and longest interval before
  using it. The moves, in order, are: introduce a value `DoseInterval`
  whose constructor holds the range check, replace the number at each
  construction with the value, and delete the two checks at the uses.
  The rule then has one home, which is [modeling values and
  entities](../../oo-modeling-values-and-entities/SKILL.md) rule 5.

- **The same switch on a type in more than one place.** `ImagingRequest`
  branches on a `ScanKind` in `preparation()`, `consentText()` and
  `followUp()`, and a fourth scan kind is about to arrive. The moves, in
  order, are: extract one method per branch inside `ImagingRequest`,
  introduce one class per scan kind behind one interface, move each
  extracted method into the class for its kind, and replace every switch
  with a message to the chosen object. The repeated condition then has
  one class per case, which is [replacing conditionals with
  polymorphism](../../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  rule 1.

- **A chain of messages through other objects.** `ResultsBoard.contact`
  sends `report.request().requester().practice().phoneNumber()` and
  hands the answer back, so it depends on a structure three objects
  away. The moves, in order, are: give `ImagingReport` a message
  `requesterPhone()` that answers what `ResultsBoard` wants, and let
  `ResultsBoard` send it; then let each object on the way answer the
  next step itself, the request asking its requester and the requester
  asking its practice, until no object sends a message to an answer it
  did not hold. Each object then talks only to its neighbours, which is
  [limiting what an object
  knows](../../oo-limiting-what-an-object-knows/SKILL.md) rule 2.

- **A class changed for two kinds of request.** `ConsultingRoom` gains
  methods when the session timetable changes and other methods when its
  equipment is due for a safety check, and the two groups read separate
  fields. The moves, in order, are: extract the safety-check fields and
  methods into an `EquipmentCheck`, move them there, keep the room as a
  collaborator of the check, and update the callers. Each class then
  answers one kind of request, which is [assigning
  responsibilities](../../oo-assigning-responsibilities/SKILL.md) rules 7
  and 8.

- **A subclass that refuses its parent's messages.** `ShortLoan`
  extends `EquipmentLoan` and raises `LoanNotExtendable` when it
  receives `extend`, which every `EquipmentLoan` promises to answer. The
  moves, in order, are: decide whether every caller must handle the
  refusal; if they need not, hold an `EquipmentLoan` inside `ShortLoan`
  and keep `extend` off the type the callers see; if they must, widen
  `EquipmentLoan`'s contract and update its callers. Either way the code
  stops promising what it cannot keep, as [honouring
  substitutability](../../oo-honouring-substitutability/SKILL.md) rule 7
  decides.

A smell that has evidence of an antipattern goes to [recognising
antipatterns](../../oo-recognising-antipatterns/SKILL.md), which names it
and orders the fixes.
