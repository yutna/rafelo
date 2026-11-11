# Finding the boundary

- [One aggregate for the plan](#one-aggregate-for-the-plan)
- [Split by the rules](#split-by-the-rules)
- [The rule that waits](#the-rule-that-waits)
- [Three questions for a boundary](#three-questions-for-a-boundary)

An aggregate starts from a rule, not from a picture of the model. Draw
the objects the rule reads and writes at once, then split again wherever
a rule can wait. A care plan shows the move.

## One aggregate for the plan

The first drawing puts the plan, its goals, its therapy sessions and its
reviews in one aggregate. Every change loads the whole plan.

Before:

```text
class CarePlan
  - id: CarePlanId
  - referral: Referral
  - goals: List<Goal>
  - sessions: List<TherapySession>
  - reviews: List<Review>
  + new(id: CarePlanId, referral: Referral)
    goals := new List<Goal>()
    sessions := new List<TherapySession>()
    reviews := new List<Review>()
  + addGoal(goal: Goal): void
    goals.add(goal)
    return
  + book(session: TherapySession): void
    raises ReferralExhausted
    if referral.approvesOneMore(sessions) then
      sessions.add(session)
    else
      raise ReferralExhausted
    return
  + addReview(review: Review): void
    reviews.add(review)
    return
```

`new List<Goal>()`, `new List<TherapySession>()` and
`new List<Review>()` are taken to mean empty lists the plan owns.
`referral.approvesOneMore(sessions)` is taken to mean that the referral
approved more sessions than the list already holds. The constructor sets
all three lists before any method reads them; each method appends once;
`book` raises without appending when the approval is used up. The plan
keeps the whole `TherapySession` object, so a load of the plan loads
every session, and a change to one session saves the whole plan.

## Split by the rules

Four rules decide the boundary:

- "A plan never books more sessions than its referral approved." This
  reads the approval and the booked session ids together, so those stay
  in the plan. If they split, two bookings could both see the last place
  free.
- "A session records who attended it and whether it happened." This
  reads and changes one session, so the session becomes its own
  aggregate.
- "Every attended session has a review in the plan." This reads a
  session and the plan's reviews together, but it can be true a moment
  after the attendance commits, so the review arrives from a later step
  (rule 4) rather than in the same transaction.
- "A goal has no identity of its own and is held only by its plan." No
  rule reads a goal on its own, so the goal list stays in the plan.

After:

```text
class CarePlan
  - id: CarePlanId
  - approvedSessions: ApprovedSessions
  - goals: List<Goal>
  - reviews: List<Review>
  - sessionIds: List<TherapySessionId>
  + new(id: CarePlanId, approvedSessions: ApprovedSessions)
    goals := new List<Goal>()
    reviews := new List<Review>()
    sessionIds := new List<TherapySessionId>()
  + addGoal(goal: Goal): void
    goals.add(goal)
    return
  + recordSession(sessionId: TherapySessionId): void
    raises ReferralExhausted
    if approvedSessions.isReachedBy(sessionIds) then
      raise ReferralExhausted
    else
      sessionIds.add(sessionId)
    return
  + addReview(review: Review): void
    reviews.add(review)
    return

class TherapySession
  - id: TherapySessionId
  - plan: CarePlanId
  - clinician: ClinicianId
  - startsAt: DateTime
  - status: SessionStatus
  + new(id: TherapySessionId, plan: CarePlanId,
      clinician: ClinicianId, startsAt: DateTime)
    status := Booked
  + recordAttended(): void
    raises SessionAlreadyRecorded
    if status = Booked then
      status := Attended
    else
      raise SessionAlreadyRecorded
    return
  + recordMissed(): void
    raises SessionAlreadyRecorded
    if status = Booked then
      status := Missed
    else
      raise SessionAlreadyRecorded
    return

enum SessionStatus
  Booked
  Attended
  Missed
```

`new List<TherapySessionId>()` is taken to mean an empty list the plan
owns. `approvedSessions.isReachedBy(sessionIds)` is taken to mean that
the list already holds as many session ids as the referral approved. The
referral's approval is copied into the plan as an `ApprovedSessions`
value when the plan is opened, so the plan no longer holds the referral
aggregate itself. The plan now holds the session's identity, not the
session itself, so a load of the plan no longer loads every session. The
session holds the plan's identity for the same reason. The
constructor sets every field before a method reads it; `recordSession`
appends one id only when the approval is not used up; a session records
its attendance once, and a second record raises instead of overwriting
it.

## The rule that waits

Recording a session's attendance and adding its review do not happen in
one transaction. The session is its own aggregate and commits alone. A
later step reads the session whose status is `Attended` and sends
`CarePlan.addReview`; when that step fails, it is retried, and a check
reports any `Attended` session whose plan has no review. A review is
taken to name the session it covers. That is rule 4's later step: the
review rule is brought true soon after the session change, not in the
same transaction. Booking is the other case: creating the session
aggregate and recording its id in the plan can happen in one transaction
when one store commits both, because the new session cannot be changing
under anyone else and a conflict on the plan refuses the whole booking.

## Three questions for a boundary

Ask these three before splitting or joining aggregates. They are the same
questions at every size.

1. What must be true after every change? The rule names the objects that
   cannot be separated. Booking never exceeds the approval, so the
   approval and the booked ids stay together.
2. Who changes it at the same time? Two receptionists booking the last
   place must not both succeed; one aggregate and one version or one
   uniqueness check settles it. Two people editing different sessions do
   not collide once the sessions are separate.
3. How much does one change load? If opening one session loads the goals
   and every review, the boundary is too large. If every check needs to
   load every session, the boundary is too small or the check belongs
   outside the aggregates.

The answers can pull against each other. Rule 5 of the skill says to keep
the aggregate as small as its rules allow, and rule 6 says to check a
rule over many aggregates outside them.
