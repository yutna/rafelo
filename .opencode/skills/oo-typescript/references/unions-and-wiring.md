# Notice Outcomes and the Composition Root

This file follows one feature through rules 5 and 6: the front desk's
notice to a patient who missed a visit, the answer each notice draws,
and the one place that builds the service sending the notice and
recording it. The types share one file here to keep the example short;
in the code base each has its own.

- [The closed set](#the-closed-set)
- [Wiring the collaborators](#wiring-the-collaborators)
- [A worked change](#a-worked-change)

## The closed set

```typescript
export type NoticeOutcome =
  | { readonly kind: 'reached'; readonly agreedWhen: string }
  | { readonly kind: 'no-answer' }
  | { readonly kind: 'wrong-number'; readonly reportedBy: string }

export class MissedVisitDesk {
  answer(outcome: NoticeOutcome): string {
    switch (outcome.kind) {
      case 'reached':
        return `book the visit at ${outcome.agreedWhen}`
      case 'no-answer':
        return 'try again at another hour'
      case 'wrong-number':
        return `ask reception about ${outcome.reportedBy}`
      default: {
        const unhandled: never = outcome
        return unhandled
      }
    }
  }
}
```

- `NoticeOutcome` is a discriminated union: each case is an object type
  with its own literal `kind`, so the set of answers is closed where the
  clinic closes it (rule 5).
- `MissedVisitDesk.answer` names every case in a `switch`, and its
  `default` branch assigns the narrowed value to a `never`-typed
  constant, so the compiler rejects the method when a new case joins
  the union (rule 5).
- `agreedWhen` and `reportedBy` are read only in their own case, where
  the `kind` check has narrowed the union to that case.
- The fence stores nothing.

## Wiring the collaborators

```typescript
declare const patientIdBrand: unique symbol
export type PatientId = string & { readonly [patientIdBrand]: true }

export interface NoticeChannel {
  send(patient: PatientId, text: string): void
}

export interface NoticeLog {
  record(patient: PatientId): void
}

export class MissedVisitService {
  readonly #channel: NoticeChannel
  readonly #log: NoticeLog

  constructor(channel: NoticeChannel, log: NoticeLog) {
    this.#channel = channel
    this.#log = log
  }

  sendNotice(patient: PatientId, text: string): void {
    this.#channel.send(patient, text)
    this.#log.record(patient)
  }
}

export class PrintedNoticeChannel implements NoticeChannel {
  send(patient: PatientId, text: string): void {
    console.log(`to ${patient}: ${text}`)
  }
}

export class WrittenNoticeLog implements NoticeLog {
  readonly #patients: PatientId[] = []

  record(patient: PatientId): void {
    this.#patients.push(patient)
  }
}

export function startMissedVisitNotices(): MissedVisitService {
  const channel = new PrintedNoticeChannel()
  const log = new WrittenNoticeLog()
  return new MissedVisitService(channel, log)
}
```

- `NoticeChannel` and `NoticeLog` are ports the domain owns; each names
  what the service sends, not the outside system behind it.
- `MissedVisitService` takes both collaborators through its constructor
  and stores them in `#private` fields, so the constructor says what it
  needs and a test passes stand-ins (rule 6).
- `PrintedNoticeChannel` and `WrittenNoticeLog` are the adapters at the
  edge. `startMissedVisitNotices` is the composition root: it builds
  both adapters and gives them to the service, and no other code names
  them (rule 6).
- The service stores its two collaborators; the log adapter stores each
  patient identifier in its own array, under that identifier, in no
  transaction the fence shows.

## A worked change

The clinic starts recording when a patient declines another visit
after a missed one, and why.

1. The team adds a fourth case to `NoticeOutcome`,
   `{ readonly kind: 'declined'; readonly reason: string }`.
2. The compiler rejects `MissedVisitDesk.answer`, whose `default`
   branch now assigns a `declined` outcome to a `never`-typed constant,
   and the team adds a case that asks the front desk to tell the
   clinician the reason before the `default` branch.
3. `MissedVisitService` and `startMissedVisitNotices` do not change: the
   new case is data on an outcome, not a collaborator, and the service
   still takes its channel and its log through the constructor.

The change ends with `MissedVisitDesk.answer` naming all four outcomes
and with `startMissedVisitNotices` still the only place that builds
`PrintedNoticeChannel` and `WrittenNoticeLog`, as rules 5 and 6 ask.
