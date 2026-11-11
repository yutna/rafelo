# Pattern index

This index lists the patterns this pack names, in alphabetical order, with
one sentence each and the skill that treats or names each. The names are
common vocabulary. Architecture styles are left to
[the layering skill][layering], and the catalogue in
[the choosing-a-pattern skill][choosing-pattern] groups the object
patterns by problem.

- **Abstract Factory.** Answers several products that vary together
  and must come from one family. [Choosing a pattern][choosing-pattern]
- **Active Object.** Answers changing state that callers must not wait
  on, with one owner that takes requests from a queue and answers each
  later. [Managing shared state][shared-state]
- **Active Record.** Answers a module whose classes mirror its tables
  and hold few rules, with an object that is one table row and saves
  itself. [Taming persistence][persistence]
- **Adapter.** Answers a port the domain owns by translating an
  outside system's interface into the messages the port declares.
  [Inverting dependencies][inverting]
- **Aggregate.** Answers which objects one rule must keep true at
  every change, around one root that every change goes through.
  [Designing aggregates][aggregates]
- **Anti-corruption Layer.** Answers a context that depends on a
  model it does not control, with one translator at its edge that
  turns the other model's terms into its own.
  [Bounding contexts][contexts]
- **Application Service.** Answers where one use case runs, as the object
  that loads aggregates, sends them commands, stores them and ends the
  transaction. [Placing domain logic][placing]
- **Bridge.** Answers two dimensions that vary independently, where
  one hierarchy would multiply the classes.
  [Choosing a pattern][choosing-pattern]
- **Builder.** Answers many optional parts assembled before the
  object exists, with the required parts known up front and one step
  that checks the whole. [Constructing valid objects][constructing]
- **Bulkhead.** Answers one slow dependency that would otherwise
  use every worker. [Making work reliable][reliable]
- **Chain of Responsibility.** Answers several handlers that may
  take a request in turn, with the set or order that varies.
  [Choosing a pattern][choosing-pattern]
- **Channel.** Answers a lab result leaving without the sender
  naming the lab. [Choosing a pattern][choosing-pattern]
- **Circuit Breaker.** Answers a dependency that keeps failing by
  stopping the calls and trying again later.
  [Making work reliable][reliable]
- **Command.** Answers an action that must be queued, stored, logged,
  undone or retried, so it stays an object that carries its data.
  [Patterns the language provides][language-patterns]
- **Command and Query Separation.** Answers whether a method changes
  state or returns an answer, keeping a command and a query apart.
  [Encapsulating state and behaviour][state-and-behaviour]
- **Competing Consumers.** Answers several workers taking from one
  reminder queue, where each message goes to one of them at a time.
  [Choosing a pattern][choosing-pattern]
- **Composite.** Answers a part and a whole of the same items that
  answer the same messages, so callers do not branch on the shape.
  [Choosing a pattern][choosing-pattern]
- **Composition Root.** Answers where the object graph is built and
  connected: one place at the program's edge.
  [Inverting dependencies][inverting]
- **Conformist.** Answers a context content to adopt another model,
  taking its words as they are with no translation of its own.
  [Bounding contexts][contexts]
- **Consumer-driven Contract.** Answers a contract where the
  reader's recorded expectations drive the tests the publisher keeps
  green. [Crossing system boundaries][crossing]
- **Context Map.** Answers which context depends on which and how
  they agree, written down for every pair that talks.
  [Bounding contexts][contexts]
- **Correlation Identifier.** Answers one incident followed across
  threads and systems, with one identity given to a request where it
  enters and carried on every record and message it causes.
  [Designing what to record][records]
- **Data Mapper.** Answers a class whose fields or rules part from
  its table, with a separate object that moves data between the
  domain and the store. [Taming persistence][persistence]
- **Data Transfer Object.** Answers data that crosses a process or
  layer boundary, carrying it as plain data with no business rules.
  [Deciding object or data][object-or-data]
- **Dead-letter Channel.** Answers a message no handler can
  process, by keeping it for a person.
  [Choosing a pattern][choosing-pattern]
- **Decorator.** Answers a step that wraps an object without
  changing the messages its callers send, while the combinations
  vary. [Choosing composition over inheritance][composition]
- **Domain Event.** Answers a change other parts must react to,
  named in the past tense and carrying the identities and facts its
  handlers need. [Publishing domain events][events]
- **Domain Model.** Answers rules that interact and grow, held in
  objects that carry both data and rules. [Placing domain logic][placing]
- **Domain Service.** Answers an operation no single aggregate can
  decide, in a stateless object named for the clinic activity it
  performs. [Placing domain logic][placing]
- **Entity.** Answers a concept with a history, identified by an
  identifier assigned once and compared by it.
  [Modeling values and entities][values]
- **Event Sourcing.** Answers an aggregate whose past states must be
  rebuilt exactly, by storing its events as the record of truth.
  [Separating reads from writes][reads]
- **Facade.** Answers one request for one clinic job over a complex
  subsystem, through a small interface that does the whole job.
  [Hiding implementation][hiding]
- **Factory Method.** Answers creation that varies with the
  subclass, through one creation step the subclass overrides.
  [Choosing a pattern][choosing-pattern]
- **Flyweight.** Answers many objects that share a large immutable
  part while the varying part is small.
  [Choosing a pattern][choosing-pattern]
- **Humble Object.** Answers an edge that is hard to test, by
  keeping in it only the code its framework needs and sending the
  rest to an object a test can drive. [Layering the system][layering]
- **Idempotent Receiver.** Answers a repeated event, by having each
  handler check whether it has handled that event before it changes
  anything. [Publishing domain events][events]
- **Identity Map.** Answers two copies of one object in one
  transaction, by returning the object already loaded for that
  identity. [Taming persistence][persistence]
- **Interpreter.** Answers a small grammar that is evaluated and
  changes often, such as an eligibility expression or a reminder
  schedule. [Choosing a pattern][choosing-pattern]
- **Iterator.** Answers a walk over a collection whose storage the
  caller must not know, with the language's own iteration rather than
  a hand-written class.
  [Patterns the language provides][language-patterns]
- **Lazy Load.** Answers an association loaded when it is first
  touched, kept inside its aggregate and its transaction.
  [Taming persistence][persistence]
- **Mediator.** Answers several colleagues that must coordinate
  while none knows all the others, through one mediator.
  [Choosing a pattern][choosing-pattern]
- **Memento.** Answers an object's state captured and restored
  without exposing its fields to the capturer.
  [Choosing a pattern][choosing-pattern]
- **Message Bus.** Answers systems that exchange messages through one
  shared channel and one message format they all use, so none connects
  to each of the others; a domain object never holds one.
  [Publishing domain events][events]
- **Message Translator.** Answers a partner's encounter becoming
  the clinic's visit. [Choosing a pattern][choosing-pattern]
- **Model-view-controller.** Answers a screen split into a model, a
  view and a controller, with the controller part of a presentation
  object. [Separating presentation from domain][presentation]
- **Model-view-presenter.** Answers a screen with a presenter
  between the view and the model, holding the screen's state and
  telling the view what to show.
  [Separating presentation from domain][presentation]
- **Model-view-viewmodel.** Answers a screen whose view binds to a view
  model that the toolkit keeps in step with it.
  [Separating presentation from domain][presentation]
- **Monitor Object.** Answers changing state that several threads use,
  by holding one lock for the whole of each method, so a check and its
  change are one step. [Managing shared state][shared-state]
- **Null Object.** Answers a collaborator that may be absent where
  doing nothing is right for every caller, with an object of the same
  type that does nothing. [Designing failure behaviour][failure]
- **Observer.** Answers one change with several reactions, where
  the changing object must not know each one and the change is
  complete without them. [Publishing domain events][events]
- **Open Host.** Answers a depended-on context with many consumers, by
  publishing one stable interface and one message language rather than
  one per consumer. [Bounding contexts][contexts]
- **Outbox.** Answers an event that must not be lost, by storing it
  with the change in one transaction and sending it by a relay
  afterwards. [Publishing domain events][events]
- **Passive View.** Answers a view that sets no widget and holds no
  decision, so the presenter sets every widget through the view's
  messages. [Separating presentation from domain][presentation]
- **Ports and Adapters.** Answers an outside system the domain must
  not name, with a port the domain owns and an adapter that answers
  it. [Inverting dependencies][inverting]
- **Presentation Model.** Answers one screen's state and logic,
  held in an object shaped for the screen rather than the domain.
  [Separating presentation from domain][presentation]
- **Process Manager.** Answers a process of several steps that
  branches, waits or must show where it stands, with one stored object
  that reacts to each step's event and sends the next command.
  [Making work reliable][reliable]
- **Projection.** Answers read rows kept current for one screen, by
  a handler of the domain events that can rebuild them from scratch.
  [Separating reads from writes][reads]
- **Prototype.** Answers an object that must be copied without the
  caller knowing its class, where copying is cheaper or safer than
  rebuilding. [Choosing a pattern][choosing-pattern]
- **Proxy.** Answers a stand-in for the real object that delays,
  guards or records access while callers send the same messages.
  [Choosing a pattern][choosing-pattern]
- **Publish and Subscribe.** Answers billing hearing of a
  cancellation without being named.
  [Choosing a pattern][choosing-pattern]
- **Published Language.** Answers consumers that must share words
  with a publisher, through one stable message language published for
  every consumer. [Bounding contexts][contexts]
- **Query Object.** Answers a search whose criteria combine freely,
  by carrying them to the repository as one object.
  [Designing repositories][repositories]
- **Read Model.** Answers a read too slow or over too many tables
  for the write store, with a store of rows shaped for one screen.
  [Separating reads from writes][reads]
- **Repository.** Answers where an aggregate is found and stored,
  through one collection of whole aggregates that speaks the domain's
  types. [Designing repositories][repositories]
- **Request and Reply.** Answers booking waiting for an insurer's
  answer before it finishes. [Choosing a pattern][choosing-pattern]
- **Retry.** Answers a failure that may pass, by asking again.
  [Making work reliable][reliable]
- **Saga.** Answers a process over several aggregates or systems that
  cannot share one transaction, by committing each step alone and
  undoing an earlier step with a compensating step when a later one
  fails. [Making work reliable][reliable]
- **Separate Ways.** Answers two contexts whose work is complete
  without the other, by exchanging nothing.
  [Bounding contexts][contexts]
- **Service Locator.** The pack does not use a service locator:
  each collaborator is passed through the object's constructor
  instead. [Inverting dependencies][inverting]
- **Shared Kernel.** Answers two teams that need one small model,
  owned and changed together while the rest of each model stays
  apart. [Bounding contexts][contexts]
- **Singleton.** The pack does not use a singleton: the one
  instance is made at the composition root and passed in through
  constructors instead. [Choosing a pattern][choosing-pattern]
- **Special Case.** Answers an absent or unusual case that every
  caller would treat alike, with an object of the same type that
  gives that case's answer. [Designing failure behaviour][failure]
- **Specification.** Answers one rule used both to check one
  aggregate and to select many, as a domain object that says whether
  an aggregate meets it. [Designing repositories][repositories]
- **State.** Answers behaviour that changes with an object's own
  status, with one object per status that the object replaces as its
  status changes. [Replacing conditionals with polymorphism][polymorphism]
- **Strangler Fig.** Answers an old part too large to replace at once,
  by routing its callers to new code one capability at a time until
  nothing reaches the old part. [Working with legacy code][legacy]
- **Strategy.** Answers a policy chosen from outside and fixed for
  the object's life, arriving through the constructor.
  [Replacing conditionals with polymorphism][polymorphism]
- **Supervising Controller.** Answers a view that binds plain
  fields itself for values needing no decision, leaving the decisions
  to the presenter. [Separating presentation from domain][presentation]
- **Table Module.** Answers tooling built around sets of records,
  with one class per table that acts on all its rows.
  [Placing domain logic][placing]
- **Template Method.** Answers several jobs that run the same steps
  in order with one step varying, by leaving that step to a
  subclass; where it can, the pack passes the step in instead.
  [Patterns the language provides][language-patterns]
- **Test Double.** Answers a collaborator a test cannot use as it is,
  with a stand-in that answers the same interface: a dummy, a stub, a
  spy, a mock or a fake. [Testing object-oriented code][testing]
- **Timeout.** Answers a wait for an answer, by bounding how long it
  may take. [Making work reliable][reliable]
- **Tolerant Reader.** Answers a reply with fields the clinic does
  not know, by taking the fields it knows and ignoring the rest.
  [Crossing system boundaries][crossing]
- **Transaction Script.** Answers a module of a few independent
  rules, with one procedure per request over a shared data-access
  object. [Placing domain logic][placing]
- **Unit of Work.** Answers when loaded objects are written, through
  a session that tracks them and writes their changes at commit, one
  per use case. [Taming persistence][persistence]
- **Value Object.** Answers a concept interchangeable with any other
  of the same contents, immutable and compared by all of them.
  [Modeling values and entities][values]
- **View Model.** Answers a presentation model a toolkit binds to,
  writing what the user types and redrawing the screen when it
  changes. [Separating presentation from domain][presentation]
- **Visitor.** Answers new operations over a fixed set of cases, by
  sending each case to an object that adds the operation.
  [Patterns the language provides][language-patterns]

[aggregates]: ../../oo-designing-aggregates/SKILL.md
[choosing-pattern]: ../../oo-choosing-a-pattern/SKILL.md
[composition]: ../../oo-choosing-composition-over-inheritance/SKILL.md
[constructing]: ../../oo-constructing-valid-objects/SKILL.md
[contexts]: ../../oo-bounding-contexts/SKILL.md
[crossing]: ../../oo-crossing-system-boundaries/SKILL.md
[events]: ../../oo-publishing-domain-events/SKILL.md
[failure]: ../../oo-designing-failure-behaviour/SKILL.md
[hiding]: ../../oo-hiding-implementation/SKILL.md
[inverting]: ../../oo-inverting-dependencies/SKILL.md
[language-patterns]: ../../oo-patterns-the-language-provides/SKILL.md
[layering]: ../../oo-layering-the-system/SKILL.md
[legacy]: ../../oo-working-with-legacy-code/SKILL.md
[object-or-data]: ../../oo-deciding-object-or-data/SKILL.md
[persistence]: ../../oo-taming-persistence/SKILL.md
[placing]: ../../oo-placing-domain-logic/SKILL.md
[polymorphism]: ../../oo-replacing-conditionals-with-polymorphism/SKILL.md
[presentation]: ../../oo-separating-presentation-from-domain/SKILL.md
[reads]: ../../oo-separating-reads-from-writes/SKILL.md
[records]: ../../oo-designing-what-to-record/SKILL.md
[reliable]: ../../oo-making-work-reliable/SKILL.md
[repositories]: ../../oo-designing-repositories/SKILL.md
[shared-state]: ../../oo-managing-shared-state/SKILL.md
[state-and-behaviour]: ../../oo-encapsulating-state-and-behaviour/SKILL.md
[testing]: ../../oo-testing-object-oriented-code/SKILL.md
[values]: ../../oo-modeling-values-and-entities/SKILL.md
