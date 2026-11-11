---
name: oo-ruby
description: Use when plain Ruby with no framework leans on duck typing, mixes in a module, defines a value with Data, or reaches for method_missing or send.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Designing Objects in Ruby

**In this pack:** sizing and rule strictness are set by the core
plugin's `oo-design` skill; each rule here keeps a core rule in this
language.

## Overview

Ruby resolves a message when it is sent: a receiver answers from its
methods, or through `method_missing`, a module's methods run with the
host as `self`, and a `Data` value freezes only the value itself. This
skill applies the pack's core rules to plain Ruby, from 3.3 on, with
Minitest and no framework. It says which feature keeps each rule and
where Ruby stops helping: a contract written as a Minitest module, a
`Data` value that copies and freezes its array, an object each class
holds in place of a module, and messages defined with `def` or paired
with `respond_to_missing?`.

## When to use

- Two or more classes play one role, and nothing in the code says what
  each of them must answer.
- A value is a plain class with `attr_accessor`, or a `Data` value that
  hands out an array it holds.
- A module included by several classes reads or writes their instance
  variables.
- Code checks `is_a?`, `kind_of?`, `instance_of?` or a `case` over
  classes before sending a message.
- A test reaches a private method with `send` or reads a field with
  `instance_variable_get`.
- A class answers messages only through `method_missing`, and
  `respond_to?` says false for them.
- An object forwards several messages to one it holds, and each
  forwarding method is written by hand.

## When not to use

- A framework builds or wires the objects, such as a web framework
  whose models are table rows: outside this skill.
- The code is Python, which `oo-python` covers.
- The question is one no Ruby feature changes, such as which object
  owns a rule or where a system boundary runs: the core skills,
  starting from `oo-design`.

## Core rules

1. Rule. **Write each role's contract as one Minitest module of tests
   that the test class of every implementation includes, because
   nothing in Ruby declares the role, as
   `oo-honouring-substitutability` rules 1 and 4,
   `oo-testing-object-oriented-code` rule 1, and
   `oo-designing-interfaces` rule 5 ask.**
   Here the module's name carries the role, and each implementation's
   test class declares that its class plays it by including the module.
   Minitest is a bundled gem, and a module included in a
   `Minitest::Test` subclass has each `test_` method run for that class.

   Ruby enforces none of this: `include` adds methods and checks no
   message, so a class that includes a module missing a method fails
   only when the message is sent, and nothing makes an implementation
   include the contract. The test run is the check.

2. Rule. **Never ask which class an object is, with `is_a?`,
   `kind_of?`, `instance_of?` or a `case` over classes, before sending
   it a message, as `oo-honouring-substitutability` rule 6 asks.** A
   check puts the class into the caller: a new implementation must be
   added to the check or it takes the wrong branch, and the caller
   depends on the classes it lists rather than on the messages it
   sends. `oo-honouring-substitutability` rule 6 says the check is the
   visible sign that a subtype breaks its parent's contract, so the
   fix belongs in the subtype or the hierarchy, never in the caller.
   In Ruby, `is_a?` and `kind_of?` answer true for the class and every
   ancestor and included module, `instance_of?` answers true only for
   the exact class, and a `case` over classes uses `Module#===`, which
   answers true for an instance of the class or its descendants.

   Ruby enforces nothing here: the check answers at run time, and a
   message an implementation lacks raises `NoMethodError` only when it
   is sent. The contract test from rule 1 is what names the
   implementation that cannot answer a role's message.

3. Default. **Give a domain object readers only for what its callers
   need, no `attr_writer` or `attr_accessor`, and change its state
   through a method named for the domain action; a reader of a
   collection answers a frozen copy, as
   `oo-encapsulating-state-and-behaviour` rules 2 and 5 ask.**
   In Ruby, `attr_writer`
   and `attr_accessor` define a `name=` method, so an assignment from
   outside runs it; a class with only `attr_reader` raises
   `NoMethodError` for that assignment. `attr_reader` answers the
   object it holds, not a copy, so a caller that pushes to the array
   it receives changes the object's state; `freeze` on a copy refuses
   the caller's change with `FrozenError`. Freezing the array is not
   enough for its elements: a string inside a frozen array still
   changes in place unless the string was frozen too.

   The exception is a value written with `Data.define` (rule 4): Ruby
   gives it a reader for every member, and a reader of its collection
   answers the frozen array the value holds, because the value has no
   action that changes it and `freeze` refuses every caller's change.

   Ruby raises `NoMethodError` for the missing writer and `FrozenError`
   for the frozen array at run time; nothing enforces that a caller
   needs only the readers the object offers, and `instance_variable_set`
   still reaches the field (rule 6).

4. Default. **Write a value with `Data.define`, check its rules in an
   `initialize` that calls `super`, and freeze a copy of each
   collection it holds, as `oo-modeling-values-and-entities` rules 2
   and 3 and `oo-constructing-valid-objects` rule 3 ask.**
   In Ruby, `Data.define` gives the class a reader
   for every member, freezes each instance, and answers equality and
   hashing from all members; an assignment to a member raises
   `NoMethodError`, and two instances with equal members answer true
   to `==` and `eql?` and have the same `hash`. `with` builds a copy
   through `initialize`, so a check in an overridden `initialize` that
   calls `super` runs for the copy too. The freeze is shallow: an
   array member still changes unless the constructor copied and froze
   it, and its strings still change in place unless each string was
   frozen.

   The exception is a concept that must change while a caller holds
   it: Ruby freezes every `Data` instance and gives it no setter, so
   that concept is an entity written as a class, with a method that
   owns the rule (rule 3), not a value.

   Ruby enforces the freeze, the missing setters, the generated
   equality and the call to `initialize` from `with`; the checks in
   `initialize` run when the value is built, and nothing checks an
   input the constructor never saw.

5. Default. **Share behaviour across classes with an object each one
   holds, forwarding to it with `Forwardable`, not with a module that
   reads or writes the host's instance variables, as
   `oo-choosing-composition-over-inheritance` rules 5 and 6 ask.**
   In Ruby, `extend Forwardable` makes
   `def_delegator` and `def_delegators` define forwarding methods on
   the class, each sending the named message to the held object; a
   module's methods run with the host as `self`, so `@field` in the
   module names the host's instance variable, and `include` gives
   every host the same methods.

   The exception is a module built from a message the host already
   answers, such as `Comparable`, which answers `<`, `<=`, `==`, `>`,
   `>=`, `between?` and `clamp` from the host's `<=>`: it reads no
   instance variable, so a host's fields cannot break it.

   Ruby defines the forwarding methods at run time and starts no check
   when a module is included; nothing stops a module reading a host's
   field, and only the contract test from rule 1 checks that each held
   object answers the role.

6. Rule. **Never reach past an object's public messages from outside
   it, tests included: no `send` to a private method, no
   `instance_variable_get` or `instance_variable_set`; use
   `public_send` where the message name is data, as
   `oo-encapsulating-state-and-behaviour` rule 1,
   `oo-testing-object-oriented-code` rule 1, and
   `oo-designing-for-testability` rule 8 ask.**
   In Ruby, `send` calls a private method, and `public_send` raises
   `NoMethodError` for one; `instance_variable_get` and
   `instance_variable_set` read and write any instance variable, and a
   private method called on another receiver raises `NoMethodError`,
   while a call with `self` as its receiver reaches it. A test that
   reaches in still passes, which is the danger: the test is tied to
   one arrangement of the code.

   Ruby refuses a private call on another receiver, but `send`,
   `instance_variable_get` and `instance_variable_set` bypass that
   refusal; nothing stops a test from using them, so only the rule and
   review keep it out.

7. Default. **Define each message an object answers with `def`, where
   a reader and a search find it, and pair any `method_missing` with
   `respond_to_missing?`, as `oo-honouring-substitutability` rule 4 and
   `oo-designing-interfaces` rule 5 ask.**
   A message defined with `def`, or with `define_method`
   when its name is computed as the class is built, is in the method
   table: `respond_to?` answers true, `methods` lists it, and a reader
   or a search finds it, so the contract module from rule 1 can name
   it. `method_missing` is called by Ruby only when no method is
   found; a message it answers is absent from `methods` and, without
   `respond_to_missing?`, `respond_to?` answers false for it, so a
   caller that asks first takes the wrong branch.

   The exception is a proxy that must answer messages named by data,
   such as one that forwards a patient's stored answers by field name:
   define `method_missing` and `respond_to_missing?` from the same
   list, and keep every message the proxy itself defines with `def`.

   Ruby calls `method_missing` at run time and calls
   `respond_to_missing?` from `respond_to?`; nothing makes the two
   agree, so a caller that asks first can be told a message is absent
   while sending it would answer.

## Pattern

`Formulary` is the clinic's list of medicines a clinician may
prescribe: two formularies with the same medicines are the same
formulary, a value (`oo-modeling-values-and-entities` rule 1). The
first fence writes it as a plain class with `attr_accessor`, and the
second writes the same value with `Data.define`.

Before:

```ruby
class Formulary
  attr_accessor :medicines

  def initialize(medicines)
    @medicines = medicines
  end
end

medicines = ["paracetamol", "amoxicillin"]
formulary = Formulary.new(medicines)
medicines << ""
formulary.medicines = []
formulary.medicines << ""
formulary.medicines << "amoxicillin"
formulary.medicines << "amoxicillin"
```

In the Before, `attr_accessor` gives the class a writer, so
`formulary.medicines = []` replaces the value's contents (rule 4). The
constructor keeps the caller's array and the reader answers it, so
`medicines << ""` changes the value too (rule 4). Nothing refuses a
blank medicine or a duplicate (rule 4). The fence stores nothing: it
leaves out where a formulary is saved, under which identity, and in
which transaction.

After:

```ruby
Formulary = Data.define(:medicines) do
  def initialize(medicines:)
    if medicines.empty?
      raise ArgumentError, "a formulary names at least one medicine"
    end
    if medicines.any? { |medicine| medicine.strip.empty? }
      raise ArgumentError, "a formulary names each medicine"
    end
    if medicines.uniq.length != medicines.length
      raise ArgumentError, "a formulary lists a medicine once"
    end
    copies = medicines.sort.map { |medicine| medicine.dup.freeze }
    super(medicines: copies.freeze)
  end
end

formulary = Formulary.new(medicines: ["paracetamol", "amoxicillin"])
changed = formulary.with(medicines: ["paracetamol"])

begin
  formulary.medicines = []
rescue NoMethodError
  puts "a value has no setter"
end

begin
  formulary.with(medicines: [])
rescue ArgumentError => error
  puts error.message
end
```

In the After, `Formulary` is a `Data` value. Ruby freezes each
instance and gives it no setter, so the assignment raises
`NoMethodError` (rule 4). `initialize` refuses an empty list, a blank
medicine, and a duplicate, and raises `ArgumentError` with a message
that names the broken rule (rule 4). It orders the medicines,
duplicates and freezes each string, and freezes the array, so the
caller's later changes cannot reach the value; the reader answers the
frozen array the value holds (rule 4). `with` builds `changed` through
`initialize`, so the same checks run for the copy (rule 4). `==`,
`eql?` and `hash` read the same member, so two formularies with the
same medicines, in any order, compare equal and hash alike (rule 4).
The fence stores nothing: it leaves out where
a formulary is saved, under which identity, and in which transaction.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A role played by two or more classes with no contract module that
  both test classes include.
- A test that calls `send` or `instance_variable_get` to reach a
  private method or field.
- `is_a?`, `kind_of?`, `instance_of?` or a `case` over classes before
  a message.
- An `attr_accessor` on a domain object.
- An `attr_reader` that answers an array the object did not freeze.
- A `Data` value that holds an array or a hash it did not copy and
  freeze.
- A module that reads or writes its host's instance variables.
- A `method_missing` with no `respond_to_missing?`.
- A value whose rules are checked in a factory or a caller instead of
  its `initialize`.
- `Forwardable` forwarding the held object's whole interface.

## Common mistakes

- Believing a `Data` instance is deep-frozen because it is frozen.
- Believing `Data#with` skips the overridden `initialize`.
- Believing `attr_reader` answers a copy of an array.
- Believing `private` stops `send` or `instance_variable_get`.
- Believing `respond_to?` knows the messages `method_missing` answers.
- Adding `attr_accessor` to quiet a caller that assigns a field.
- Putting a value's check in a factory, so `with` skips it.
- Using `is_a?` to choose behaviour, then adding a branch per class.
- Adding a public reader or a test-only method so a test can see
  inside.
- Forwarding `@held.methods` or every message of the held object by
  habit.

## Related skills

- `oo-design` sizes a task and defines the rule labels.
- `oo-designing-interfaces` shapes a role around its caller and names
  the types that play it.
- `oo-honouring-substitutability` says what every implementation of a
  role must keep.
- `oo-testing-object-oriented-code` says which messages a test may send
  and what it may check.
- `oo-modeling-values-and-entities` decides whether a concept is a
  value or an entity, and what equality reads.
- `oo-constructing-valid-objects` makes a constructor refuse broken
  input.
- `oo-encapsulating-state-and-behaviour` keeps an invariant with the
  state it guards.
- `oo-choosing-composition-over-inheritance` decides when to hold an
  object instead of extending a class.
- `oo-designing-for-testability` keeps a test out of a class's inside.
- `oo-python` shows how the same rules read in Python.
- `oo-javascript` shows how the same rules read in a language with no
  type checker.

## Further reading

- [Mixins and contracts](references/mixins-and-contracts.md)
