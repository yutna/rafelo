---
name: oo-javascript
description: Use when plain JavaScript (JS), with no framework or types, has no interface for a contract, or needs private state, frozen values or classes, not prototypes.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Objects in JavaScript

**In this pack:** sizing and rule strictness are set by the core
plugin's `oo-design` skill; each rule here keeps a core rule in this
language.

## Overview

Plain JavaScript has no interface to declare a role and no type checker
to check that a class keeps one; the type annotations that would say it
belong to `oo-typescript`. What remains is the language and the
runtime: a `#private` field that only the class body can name, a frozen
object whose own properties cannot change, and a test that every
implementation of a role runs. This skill applies the pack's core
rules to plain JavaScript, ECMAScript 2022 or later, written as
modules, with no framework. It says where each rule lives: a test in
place of an interface, a `class` in place of an edited prototype, state
the runtime hides, a value frozen on its own object and copied where it
holds a collection, and no question about an object's class before a
message.

## When to use

- Two or more classes play one role, and nothing in the code states
  what each of them must answer.
- A rule on a field can be broken from outside, because the field is an
  ordinary property or a getter hands out the array it holds.
- A value is frozen, yet an array or an object it holds still changes.
- Code asks `instanceof`, reads `constructor`, or checks a class name
  before sending a message.
- A class is written by assigning to `Constructor.prototype`, or an
  object literal with methods has grown into something the team calls a
  class.

## When not to use

- A framework builds, decorates or wires the objects, such as a server
  framework that reads decorators or a form library that fills fields:
  outside this skill.
- The files carry type annotations, which is TypeScript:
  `oo-typescript`.
- The question is one no JavaScript feature changes, such as which
  object owns a rule or where a module boundary runs: the core skills,
  starting from `oo-design`.

## Core rules

1. Rule. **Write each role's contract as one test that every
   implementation of the role runs, because no interface declares it
   and no type checker checks it, as `oo-honouring-substitutability`
   rules 1 and 4 ask.** The test is where an implementer reads what each
   message requires, what it answers, and what stays true between
   calls, which is the place `oo-honouring-substitutability` rule 4
   gives a contract. It names the role and lists the classes that play
   it, as `oo-designing-interfaces` rule 5 asks. It sends only the
   messages a caller sends and reads only what a caller can see, as
   `oo-testing-object-oriented-code` rule 1 asks, so a second
   implementation joins the list and runs the same checks. A test that
   reaches into one class's fields passes for that class and says
   nothing about the role.

2. Default. **Write classes with `class`, never by editing a
   prototype, as `oo-patterns-the-language-provides` rule 7 asks.** A
   class body keeps the constructor, the methods and the `#private`
   fields in one place, and the body runs in strict mode, so a write to
   a frozen property throws instead of failing silently. A
   method assigned to `Constructor.prototype` is enumerable by
   default, reaches instances already created, and sits outside the
   body that holds the fields and the rules. The exception is a module
   that already builds its objects by editing a prototype and whose
   team reads that shape: a change inside that module follows its
   idiom, as `oo-patterns-the-language-provides` rule 7 weighs it,
   while a new module starts with `class`.

3. Rule. **Keep state that a rule guards in `#private` fields, which
   only the class body can name, as
   `oo-encapsulating-state-and-behaviour` rules 1 and 5 ask.** A
   `#private` field is not a property: a reference to it outside the
   class body is a syntax error, no `Object` method lists it, and a
   subclass cannot name it. An ordinary property is a slot any
   caller may write, so a caller can leave the object in a state the
   rule forbids and the method that keeps the rule never runs. The rule
   stays in the method that changes the field, and a caller gets a
   named action or a read-only view, never the collection itself, as
   rule 5 there asks.

4. Default. **Freeze a value's own object and copy what it holds,
   knowing that `Object.freeze` is shallow and leaves `#private` fields
   reassignable, so the value offers no method that changes them, as
   `oo-modeling-values-and-entities` rule 2 and
   `oo-encapsulating-state-and-behaviour` rule 6 ask.**
   `Object.freeze(value)` makes the object's own properties non-writable
   and non-configurable and answers the same object, not a copy. It is
   shallow: an array or an object held in a property stays changeable,
   so the constructor copies each mutable argument and freezes the
   copy. A `#private` field is not a property, so freezing the object
   does not stop `this.#field = ...` inside the class; what keeps a
   value is that no method does that, and every change answers a new
   value.

   The exception is a field that holds a value rather than an entity:
   because a value never changes, the constructor keeps the instance it
   was given without copying it, as `oo-modeling-values-and-entities`
   rule 2 says. A field that holds an entity of another aggregate keeps
   its identifier, as `oo-designing-aggregates` rule 3 asks, and a value
   holds no mutable entity at all: `oo-modeling-values-and-entities`
   rule 2 makes it immutable.

5. Rule. **Never ask which class an object is, by `instanceof` or by
   its `constructor`, before sending it a message, as
   `oo-honouring-substitutability` rule 6 asks.** Such a check puts the
   class into the caller: a new implementation must be added to the
   check or it takes the other branch, and the caller no longer
   depends on the role's messages. If one implementation needs a
   different message, the role's contract is wrong or that
   implementation does not keep it, and rule 6 there says to fix the
   subtype or the hierarchy, not the caller. The contract test from
   rule 1 names the implementation that breaks the role, because the
   same test runs for each one.

## Pattern

`VisitChecklist` is what the front desk prepares for a visit: two
checklists with the same visit identifier and the same items are the
same checklist, a value (`oo-modeling-values-and-entities` rule 1).
The first fence keeps its state in ordinary properties, and the
second keeps the same state in `#private` fields.

Before:

```javascript
export class VisitChecklist {
  constructor(visitId, items) {
    this.visitId = visitId
    this.items = items
  }

  add(item) {
    if (item.trim() === '') {
      throw new Error('a checklist item is blank')
    }
    if (this.items.length >= 8) {
      throw new Error('a checklist holds at most eight items')
    }
    this.items.push(item)
  }
}

const items = ['weigh the patient', 'print the summary']
const checklist = new VisitChecklist('v-3312', items)

checklist.add('book the follow-up')
checklist.items.push('')
Object.freeze(checklist)
items.push('call the insurer')
```

In the Before, `items` is an ordinary property, so
`checklist.items.push('')` adds a blank item and the check in `add`
never runs (rule 3). `Object.freeze(checklist)` freezes the checklist's
own properties and answers the same checklist; the array it holds stays
changeable, so the last push still changes the checklist (rule 4). The
fence stores nothing.

After:

```javascript
export class VisitChecklist {
  #visitId
  #items

  constructor(visitId, items) {
    if (items.length < 1 || items.length > 8) {
      throw new Error('a checklist holds one to eight items')
    }
    for (const item of items) {
      if (item.trim() === '') {
        throw new Error('a checklist item is blank')
      }
    }
    this.#visitId = visitId
    this.#items = Object.freeze([...items])
    Object.freeze(this)
  }

  get visitId() {
    return this.#visitId
  }

  items() {
    return this.#items
  }

  withItem(item) {
    return new VisitChecklist(this.#visitId, [...this.#items, item])
  }
}

const items = ['weigh the patient', 'print the summary']
const checklist = new VisitChecklist('v-3312', items)
items.push('book the follow-up')
const longer = checklist.withItem('call the insurer')
```

In the After, `visitId` and `items` are `#private` fields, so nothing
outside the class body can assign or reach them (rule 3). The
constructor copies the caller's list with `[...items]` and freezes the
copy, so the later push on the caller's list cannot reach the checklist
(rule 4). `Object.freeze(this)` freezes the checklist's own object and
answers the same checklist; it does not stop a `#private` field from
being reassigned, which is why the class offers no method that does.
`withItem` answers a new checklist built through the constructor, and
`items` answers the frozen array the checklist holds (rule 4). The
fence stores nothing.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A role played by two or more classes, with no test that each one
  runs.
- A test that reads a field or checks a class name instead of sending a
  message.
- `instanceof` or `constructor` compared before a message is sent.
- A field that a rule guards, assigned from outside the class.
- `Object.freeze` on an object that holds an array or another object.
- A value class with a method that reassigns its own `#private` fields.
- A method added by assigning to a constructor's `prototype`.
- A getter that answers the internal array rather than a frozen copy.

## Common mistakes

- Freezing an object and believing the array it holds is frozen too.
- Freezing a value and believing a `#private` field can no longer be
  reassigned.
- Believing `Object.freeze` answers a copy of the object.
- Writing `private` as though JavaScript had the TypeScript keyword.
- Choosing behaviour with `instanceof`, then adding a branch for each
  class.
- Treating a role's contract test as a unit test of one class, so a
  second implementation never runs.
- Handing out the internal array from a getter and calling it a view.
- Converting a working prototype-based module to classes in one change,
  because classes are the newer syntax.

## Related skills

- `oo-design` sizes a task and defines the rule labels.
- `oo-honouring-substitutability` says what every implementation of a
  role must keep.
- `oo-testing-object-oriented-code` says which messages a test may send
  and what it may check.
- `oo-designing-interfaces` shapes a role around its caller and names
  the types that play it.
- `oo-patterns-the-language-provides` shows when a language feature
  replaces a pattern and when a module's idiom stays.
- `oo-encapsulating-state-and-behaviour` keeps a rule beside the state
  it guards and copies a collection at the boundary.
- `oo-modeling-values-and-entities` decides what a value is and makes
  it immutable.
- `oo-typescript` applies the same rules where a type checker declares
  the contract.

## Further reading

- [Contracts in tests](references/contracts-in-tests.md)
