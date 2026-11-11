---
name: oo-typescript
description: Use when plain TypeScript (TS) with no framework mixes up same-shaped types, or needs private fields, an abstract class, a decorator or a discriminated union.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Objects in TypeScript

**In this pack:** sizing and rule strictness are set by the core
plugin's `oo-design` skill; each rule here keeps a core rule in this
language.

## Overview

TypeScript puts much of a design into the type system and then takes
some of it back: object types match by their shape, so a string that
names a patient can stand where a string that names a clinician is
expected, and `private` is a compile-time promise that leaves the
member in the JavaScript object. This skill applies the pack's core rules
to plain TypeScript, from version 5.0 on, with `strict` on and no
framework, using the ECMAScript decorators TypeScript 5.0 supports. It
says which feature keeps each rule and how the compiler and the runtime
then help: a branded identifier the compiler refuses to swap, a
`#private` field the runtime keeps out of reach, an abstract class that
holds the state its subclasses share, a discriminated union whose
`switch` a new case cannot leave half-answered, and a composition root
that names every adapter once.

## When to use

- Two types share a shape, and a value of one is passed where the other
  is meant, such as a clinician identifier where a patient identifier is
  expected.
- A field is `private`, and a cast, a bracket lookup or plain JavaScript
  reaches it, so a rule on that field can be broken from outside.
- Several implementations share a promise, and the choice between an
  interface and an abstract class is open.
- A decorator carries a value check or a state change rather than a
  framework's registration.
- A set of cases is closed, and code tests a `kind` or a status string
  in an `if` chain or in a `switch` with no `never` check.
- A class constructs its own adapter, imports a singleton, or asks a
  module-level registry for a collaborator.

## When not to use

- A framework builds or decorates the classes, such as a server
  framework that reads decorators or a UI framework that constructs its
  components: outside this skill.
- The question is one no TypeScript feature changes, such as which
  object owns a rule or where a module boundary runs: the core skills,
  starting from `oo-design`.
- The files carry no type annotations and are JavaScript, not
  TypeScript: outside this skill; `oo-javascript` says how plain
  JavaScript keeps the pack's core rules with no type checker.

## Core rules

1. Default. **Give an identifier or a value whose shape another type
   shares a brand, a mark the compiler checks, so neither can stand
   where the other is expected, as `oo-modeling-values-and-entities`
   rule 5 and `oo-designing-interfaces` rule 5 ask.** TypeScript matches
   object types by their members, so `type PatientId = string` and
   `type ClinicianId = string` are one type; a brand is the value's type
   intersected with an object type that holds a `unique symbol` member,
   and that member exists in the type only. A checked factory asserts
   the brand once at the edge, where text becomes a value, and every
   later call is checked. The exception is a type no unrelated type
   shares a shape with, such as a class with a `private` or `#private`
   member, whose compatible types must come from the same declaration: a brand
   adds a name and protects nothing.

2. Rule. **Hide state that a rule guards in `#private` fields, which the
   JavaScript runtime enforces, because `private` is a compile-time
   promise only, as `oo-encapsulating-state-and-behaviour` rules 1 and 5
   and `oo-hiding-implementation` rule 3 ask.** A `private` member does
   keep a same-shaped class out, because the member matches only the one
   from the same declaration, but it leaves an ordinary property in the
   JavaScript object: a cast, a bracket lookup or plain JavaScript reads
   and writes it, and the rule that a method keeps can be broken from
   outside. A `#private` field has no name outside the class body: the
   compiler rejects the reference, no `Object` method lists the field,
   and the runtime throws when a private name is used on an object whose
   class did not declare it. The rule still lives in a method that
   changes the field, and a caller gets a named action or a read-only
   view, never the collection itself.

3. Judgement. **Choose an interface when the implementations share only
   a promise, and an abstract class when they share state or a fixed
   order of steps that the base class owns, as `oo-designing-interfaces`
   rule 4 chooses an interface or a base class.** An interface leaves no
   run-time trace and holds no state, and a class meets it by its shape,
   so `implements` checks the promise and does not link the class to it.
   An abstract class can hold `#private` state and methods every
   subclass inherits, and `extends` binds a subclass to that state and
   to which of the base's methods the base sends itself. What tips the
   balance is whether the shared code needs state: prefer the interface
   unless the code would otherwise be repeated. A base class that stays
   open says which methods an override may replace and which of its own
   methods send them.

4. Default. **Keep every clinic rule in a method of the class it guards,
   where a test builds the object and calls it, and let a decorator hold
   no business rule, as `oo-encapsulating-state-and-behaviour` rule 1
   and `oo-working-within-a-framework` rule 1 ask.** A TypeScript 5.0
   decorator's context reaches the member it decorates, a `#private` one
   included through `context.access`, but the decorator guards only that
   member: a caller that reaches the guarded state another way skips it,
   a reader of the class does not see the rule, and a new method that
   needs it must remember the decorator. A decorator may log, time or
   register, which are concerns of the edge. The exception is a decorator
   that carries a framework's demand at the edge, such as one that
   registers a handler or a mapped field: it holds the framework's
   concern, not the clinic's, and the clinic's rule stays in a method.

5. Default. **Close a set of cases the domain closes as a discriminated
   union, a union of object types with one literal `kind` field, and
   answer it in a `switch` that names every case and whose `default`
   branch assigns the value to a `never`-typed constant, as
   `oo-making-illegal-states-impossible` rule 2 and
   `oo-patterns-the-language-provides` rule 5 ask: a case added to the
   union then fails to compile in every such `switch`.** The exception
   is a set that gains new kinds more often than new operations: give
   each kind its own class behind an interface, as
   `oo-replacing-conditionals-with-polymorphism` rule 7 weighs it.

6. Rule. **Pass every collaborator to its object through the
   constructor, and construct and connect the object graph by hand in
   one place at the program's edge, as `oo-inverting-dependencies` rules
   2, 3 and 4 ask.** A class that builds its own adapter, imports a
   singleton or asks a module-level registry hides what it needs; its
   constructor does not say the need, a missing part waits until a
   message runs, and a test must start the outside system. A required
   constructor parameter says the need, a call that leaves it out does
   not compile, and a test passes a stand-in. The composition root, a
   `main` function or the start of a request, is the only place that
   names an adapter, and it calls each constructor after the objects
   that constructor needs. A part whose lifetime the object owns, such
   as its own list of attempts, is still created by the object.

## Pattern

`MissedVisitNotice` is the front desk's notice to a patient who missed
a visit: it holds the patient, the clinician who will review the visit,
and the number of attempts made. The identifiers are both strings in
the Before, so the compiler sees one shape, and `attempts` is `private`.

Before:

```typescript
export class MissedVisitNotice {
  private attempts: number

  constructor(
    readonly patientId: string,
    readonly clinicianId: string
  ) {
    this.attempts = 0
  }

  recordAttempt(): void {
    if (this.attempts >= 3) {
      throw new Error('a notice goes out at most three times')
    }
    this.attempts += 1
  }
}

const patient = 'p-1042'
const clinician = 'c-77'

const notice = new MissedVisitNotice(patient, clinician)
notice.recordAttempt()
const escaped = notice as unknown as { attempts: number }
escaped.attempts = 9
new MissedVisitNotice(clinician, patient)
```

In the Before, `new MissedVisitNotice(clinician, patient)` passes a
clinician identifier where a patient identifier is expected and
compiles, because both are `string` (rule 1). `attempts` is `private`,
so the type checker refuses `notice.attempts`, but the field is an
ordinary property in the JavaScript object: the cast to
`{ attempts: number }` reaches it, and nine attempts break the rule
`recordAttempt` keeps (rule 2).

After:

```typescript
declare const patientIdBrand: unique symbol
declare const clinicianIdBrand: unique symbol

export type PatientId = string & { readonly [patientIdBrand]: true }
export type ClinicianId = string & { readonly [clinicianIdBrand]: true }

export function asPatientId(value: string): PatientId {
  if (value.trim() === '') {
    throw new Error('a patient identifier is blank')
  }
  return value as PatientId
}

export function asClinicianId(value: string): ClinicianId {
  if (value.trim() === '') {
    throw new Error('a clinician identifier is blank')
  }
  return value as ClinicianId
}

export class MissedVisitNotice {
  #attempts: number

  constructor(
    readonly patientId: PatientId,
    readonly clinicianId: ClinicianId
  ) {
    this.#attempts = 0
  }

  recordAttempt(): void {
    if (this.#attempts >= 3) {
      throw new Error('a notice goes out at most three times')
    }
    this.#attempts += 1
  }
}

const patient = asPatientId('p-1042')
const clinician = asClinicianId('c-77')

new MissedVisitNotice(patient, clinician)
// @ts-expect-error a clinician identifier is no patient identifier
new MissedVisitNotice(clinician, patient)
```

In the After, `PatientId` and `ClinicianId` are brands: each is a
`string` intersected with an object type that holds its own
`unique symbol`, a member that exists in the type only, so the compiler
refuses `new MissedVisitNotice(clinician, patient)` (rule 1).
`asPatientId` and `asClinicianId` check the raw text once at the edge
and assert the brand; the `@ts-expect-error` line keeps the mix-up, so
the compile passes only while the compiler refuses it. `attempts` is
`#private`: the field has no name outside the class body, so a cast can
add an ordinary `attempts` property but cannot reach `#attempts`, and
`recordAttempt` is still the method that keeps the rule (rule 2). The
constructor sets `patientId`, `clinicianId` and `#attempts` before
`recordAttempt` reads `#attempts`. The fences store nothing.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- Two identifiers of the same shape, such as a patient identifier and a
  clinician identifier, both typed `string`.
- A `private` field that a rule guards, with a cast, a bracket lookup or
  plain JavaScript able to reach it.
- A getter that hands out an internal array, or a setter on a field a
  rule guards.
- A decorator that checks a value or changes a state, rather than
  registering the class or method at the edge.
- A `kind` or a status string tested with `if` chains in several places.
- A `switch` over a closed set with no `never` check in its `default`
  branch.
- A class that constructs its own adapter, imports a singleton, or
  reads a module-level registry.
- An abstract class that holds no state and fixes no order, where an
  interface would do.
- An interface that copies every public member of one class.

## Common mistakes

- Branding a type that no other type shares a shape with, adding a cast
  for nothing.
- Using `private` for state a rule guards and believing the runtime
  enforces it.
- Treating a `private` member's effect on type compatibility as privacy
  at run time.
- Putting a rule in a decorator, where a caller that reaches the state
  another way skips it.
- Letting a `switch` over a closed set fall back to a string instead of
  assigning the value to `never`.
- Building an adapter inside the service that uses it, so a test must
  start the outside system.
- Naming an adapter in a domain class or in a module-level registry,
  then calling it a constructor parameter.
- Choosing an abstract class for a promise that needs no state.
- Adding a getter for an internal collection that callers then change.

## Related skills

- `oo-design` sizes a task and defines the rule labels.
- `oo-modeling-values-and-entities` decides whether a concept is a value
  or an entity, and what equality compares.
- `oo-designing-interfaces` shapes an interface around its caller and
  chooses an interface or a base class.
- `oo-encapsulating-state-and-behaviour` keeps an invariant with the
  state it guards.
- `oo-hiding-implementation` keeps a module's decisions behind a small
  interface.
- `oo-working-within-a-framework` says which framework demands the edge
  may meet and which rules stay in the domain.
- `oo-making-illegal-states-impossible` closes a set of states where the
  domain closes it.
- `oo-patterns-the-language-provides` shows when a language feature
  replaces a pattern.
- `oo-replacing-conditionals-with-polymorphism` weighs new kinds
  against new operations.
- `oo-inverting-dependencies` puts a port beside the domain and builds
  the graph at the edge.

## Further reading

- [Outcomes and wiring](references/unions-and-wiring.md)
