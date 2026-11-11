# Contracts in Tests

This file follows one role through rule 1: the billing desk's fee
schedule, two classes that play it, and the one test each class runs.
The classes share one file here to keep the example short; in the code
base each has its own.

- [The role and its implementations](#the-role-and-its-implementations)
- [The contract test](#the-contract-test)
- [A worked change](#a-worked-change)

## The role and its implementations

`FeeSchedule` is the role: a store that answers the fee the billing desk
recorded for a service code, and replaces that fee when the desk sets
another. `MapFeeSchedule` holds a `Map`; `RecordFeeSchedule` holds a
plain object with no prototype, so every code is an own key and no
inherited name answers by accident.

Neither class extends the other, and neither names the role in its
code. In a language with interfaces the role would be declared once;
here the contract test names it and lists both classes, as rule 1 and
`oo-designing-interfaces` rule 5 ask. Each schedule stores its fees in
the process, under the service code, in no transaction this fence
shows.

```javascript
export class MapFeeSchedule {
  #fees = new Map()

  setFee(code, amount) {
    this.#fees.set(code, amount)
  }

  feeFor(code) {
    return this.#fees.get(code) ?? null
  }
}

export class RecordFeeSchedule {
  #fees = Object.create(null)

  setFee(code, amount) {
    this.#fees[code] = amount
  }

  feeFor(code) {
    return Object.hasOwn(this.#fees, code) ? this.#fees[code] : null
  }
}
```

- `MapFeeSchedule` keeps the fees in a `Map`, so a code is a key and
  `feeFor` reads it with `get` (rule 1).
- `RecordFeeSchedule` keeps the fees as own keys of an object with no
  prototype, so a code such as `constructor` cannot answer through
  `Object.prototype` (rule 1).
- Both classes answer `null` for a code they hold no fee for, and both
  replace the fee when `setFee` records the code again (rule 1).

## The contract test

The test is the role's contract where an implementer reads it (rule 1).
Its comment states what each message requires and answers; its list
names the classes that play the role; its one test function runs for
each of them, so a new implementation joins the list and inherits every
check. The test sends only `feeFor` and `setFee`, and checks only the
answers those messages give, as `oo-testing-object-oriented-code` rule 1
asks.

```javascript
import test from 'node:test'
import assert from 'node:assert/strict'

import { MapFeeSchedule, RecordFeeSchedule } from './fee-schedules.mjs'

// The fee schedule role. A schedule answers the fee the billing desk
// recorded for a service code.
// -- feeFor(code) answers the amount recorded under code, or null when
//    no amount is recorded there.
// -- setFee(code, amount) records amount under code and replaces the
//    amount recorded there before.
// -- setFee for one code does not change the fee recorded for another.
const implementations = [
  ['map', () => new MapFeeSchedule()],
  ['record', () => new RecordFeeSchedule()]
]

for (const [name, makeSchedule] of implementations) {
  test(`the ${name} schedule keeps the fee schedule role`, () => {
    const schedule = makeSchedule()
    assert.strictEqual(schedule.feeFor('first-visit'), null)
    schedule.setFee('first-visit', 45)
    assert.strictEqual(schedule.feeFor('first-visit'), 45)
    schedule.setFee('first-visit', 50)
    assert.strictEqual(schedule.feeFor('first-visit'), 50)
    schedule.setFee('dose-review', 30)
    assert.strictEqual(schedule.feeFor('first-visit'), 50)
    assert.strictEqual(schedule.feeFor('dose-review'), 30)
  })
}
```

- The `implementations` list is the declaration the role has instead of
  an interface: each entry names a class and makes a fresh schedule
  (rule 1).
- Every check in the test sends one of the role's messages and reads
  its answer, so each check holds for any class that keeps the role,
  and a class that breaks one of these promises fails it (rule 1).
- The schedules keep their fees in memory, under the service code, in
  no transaction this fence shows.

## A worked change

The billing desk needs the schedule to keep the order in which codes
first arrived, so the team writes `ListedFeeSchedule` over an array and
adds it to the test's list.

The first version appends every `setFee` to the array, and `feeFor`
answers the first entry for a code. The contract test fails: after
`setFee('first-visit', 50)`, `feeFor('first-visit')` answers 45, because
the entry recorded before the replacement is the first one. The role
promised the new amount, so this class does not keep it.

The team changes `setFee` to replace the entry for a code in place, and
to append only a code it does not hold.

```javascript
export class ListedFeeSchedule {
  #entries = []

  setFee(code, amount) {
    const index = this.#entries.findIndex((entry) => entry.code === code)
    if (index === -1) {
      this.#entries.push({ code, amount })
      return
    }
    this.#entries[index] = { code, amount }
  }

  feeFor(code) {
    const entry = this.#entries.find((candidate) =>
      candidate.code === code)
    return entry === undefined ? null : entry.amount
  }
}
```

- `ListedFeeSchedule` keeps one entry per code and answers it with
  `find`, so a code's fee is replaced rather than shadowed (rule 1).
- The class stores its fees in the process, under the service code, in
  no transaction this fence shows.
- The test's list gains `['listed', () => new ListedFeeSchedule()]`,
  and its import names the class; the checks in the test do not change.

The change ends with one contract test that all three implementations
run and pass, so each can stand where the role is expected, as rule 1
asks.
