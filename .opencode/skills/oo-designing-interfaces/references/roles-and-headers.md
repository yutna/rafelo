# Roles and headers

- [A role and a header](#a-role-and-a-header)
- [One class, several roles](#one-class-several-roles)
- [When to split](#when-to-split)
- [Interface or base class](#interface-or-base-class)

An interface is a promise made to a caller. A role interface is named
for what that caller needs; a header interface copies the public
members of a class. This reference compares the two, shows one class in
two roles, and chooses between an interface and a base class that owns
a fixed order of steps.

## A role and a header

A header interface takes every public message of one class and declares
it again. Each change to the class must be made twice, and a caller
still sees messages it never sends. The name also follows the class
rather than the caller's need.

```text
interface PharmacyInterface
  + reserve(slot: Slot): void
  + restock(slot: Slot): void
  + report(): String

class Pharmacy implements PharmacyInterface
  - doses: List<Slot>
  + new()
    doses := new List<Slot>()
  + reserve(slot: Slot): void
  + restock(slot: Slot): void
  + report(): String

class VaccinationDesk
  - pharmacy: PharmacyInterface
  + new(pharmacy: PharmacyInterface)
  + prepare(slot: Slot): void
    pharmacy.reserve(slot)
    return

class MonthlyStockReport
  - pharmacy: PharmacyInterface
  + new(pharmacy: PharmacyInterface)
  + run(): String
    return pharmacy.report()
```

`Slot` is used only as a type here, with the shape `notation.md` gives
it. `Pharmacy` shows its three methods as signatures only.
`new List<Slot>()` is taken to make an empty list. `reserve` is taken to
record one dose for the slot once, `restock` to return one dose to the
stock for the slot once, and `report` to return the month's stock as
text. `VaccinationDesk` sends only `reserve` and `MonthlyStockReport`
only `report`, yet both hold `PharmacyInterface`, so a change to
`restock` reaches both.

## One class, several roles

A role interface names one caller's need and declares only the messages
that caller sends. `DoseStock` says that a vaccination can reserve one
dose; `StockReport` says that the monthly report can ask for the stock.
`Pharmacy` plays both roles and keeps `restock` outside them.

```text
interface DoseStock
  + reserve(slot: Slot): void

interface StockReport
  + report(): String

class Pharmacy implements DoseStock, StockReport
  - doses: List<Slot>
  + new()
    doses := new List<Slot>()
  + reserve(slot: Slot): void
  + restock(slot: Slot): void
  + report(): String

class VaccinationDesk
  - stock: DoseStock
  + new(stock: DoseStock)
  + prepare(slot: Slot): void
    stock.reserve(slot)
    return

class MonthlyStockReport
  - stock: StockReport
  + new(stock: StockReport)
  + run(): String
    return stock.report()
```

`class Pharmacy implements DoseStock, StockReport` is taken to mean
that `Pharmacy` implements both interfaces; the notation has no syntax
for a list of implemented interfaces. `DoseStock` declares exactly
`reserve(slot: Slot): void`, the message `VaccinationDesk` sends to
reserve a dose for a vaccination visit. `Pharmacy` keeps `restock` as
its own public method. Each caller holds one role, set by its
constructor, so a change to `restock` reaches neither caller. A change
to `reserve` reaches only `VaccinationDesk`, and a stand-in for
`StockReport` answers only `report`.

## When to split

Split an interface when its callers use separate parts of it. If one
caller sends every message, leave the interface whole; one role is
already the right size. `DoseStock` is that case: one message, one
caller, and no second part to separate.

Do not split every message into its own interface. Two messages that
every caller sends together belong to one role, and separate interfaces
would make each caller hold and pass both. The question is which
messages travel together for a caller, not how many messages an
interface holds.

## Interface or base class

Choose an interface when the implementations share only a promise.
Choose an abstract base class when they share state or a fixed order of
steps that the base class owns. The notation has no keyword for an
abstract base class; a `--` comment marks one, as
`oo-honouring-substitutability` marks a closed class.

```text
class StockRun
  -- abstract: each kind of stock run extends it and keeps the order
  - slot: Slot
  + new(slot: Slot)
  + run(): void
    raises NoFreeDose
    -- sends checkAvailability, then take, then record, once each
    checkAvailability()
    take()
    record()
    return
  + checkAvailability(): void
    raises NoFreeDose
    -- an override keeps: raises NoFreeDose when the slot has no free dose
  + take(): void
    -- an override keeps: reserves one dose for the slot
  + record(): void
    -- an override keeps: records the reserved dose once
```

`StockRun` marks itself abstract in its comment, and its three steps
appear as signatures only. Its constructor sets `slot` before `run`
sends the steps. `run` owns the order, so every implementation gets the
same sequence, and the comment beside each step says what an override
keeps. That is the case an interface does not cover: the state and the
order live in one place. An interface would put the sequence in every
implementation and bind none of them to it.
