# Patterns by problem

- [Steps and policies](#a-step-or-a-policy-varies)
- [Standing in and wrapping](#an-object-stands-in-for-or-wraps-another)
- [Creating objects](#creating-objects-varies)
- [A group as one, or walked](#a-group-of-objects-is-treated-as-one-or-walked)
- [Sharing objects](#objects-are-shared-rather-than-made-anew)
- [Reacting without knowing](#objects-react-without-knowing-each-other)
- [State kept and restored](#state-is-kept-and-restored)

This reference gives twenty-three object patterns. The entries are
grouped by the problem a clinic team meets; each entry gives the
symptom, the force, the cost and, where this pack has one, the skill
that takes the pattern further.

## A step or a policy varies

- **Strategy.** A clinic step has several rules, such as which channel
  sends a reminder or how a fee is worked out, and the caller chooses
  one. The force is a policy that is chosen from outside and stays fixed
  for the object's life. The cost is an interface, a class per policy
  and a collaborator every caller holds. When the choice comes from
  outside and stays fixed, rule 5 of [replacing conditionals with
  polymorphism](../../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  chooses a strategy.

- **Template Method.** Several clinic jobs run the same steps in the
  same order, such as booking, rescheduling and cancelling, and only one
  step differs. The force is a fixed order that is shared while one step
  varies. The cost is a parent class, an overridable step for each
  variation and a written contract for which steps a subclass may
  override.

- **State.** An appointment behaves differently as its own status
  changes, and the same status check appears in several methods. The
  force is behaviour that changes with the object's own status, where
  the object's actions move it from one status to the next. The cost is
  an interface, a class per status and the place that chooses the first
  status. Rule 4 of [replacing conditionals with
  polymorphism](../../oo-replacing-conditionals-with-polymorphism/SKILL.md)
  gives each status its own object, and rule 5 there says a state is
  replaced as the object's status changes.

- **Command.** A request, such as booking, rescheduling or cancelling an
  appointment, must be handed on as a value, queued, retried, logged or
  undone. The force is a request that must travel without the sender
  knowing the object that carries it out. The cost is a class per
  request and a place that chooses which one to run; every reader must
  learn the command vocabulary.

## An object stands in for or wraps another

- **Adapter.** A lab's result service, a text gateway or an insurer's
  API speaks its own names, and every caller translates the clinic's
  request into them. The force is an outside interface that differs from
  the one the domain needs, where the outside side varies or takes time.
  The cost is a port beside the domain and one adapter per outside
  system, plus the translation in each adapter. Rule 1 of [inverting
  dependencies](../../oo-inverting-dependencies/SKILL.md) puts the port
  beside the domain and lets an adapter answer it.

- **Decorator.** The same step, such as adding the how-to-cancel line or
  a confidentiality footer, is copied around a core operation, and the
  steps must be able to combine. The force is a step that wraps an
  object without changing the messages its callers send, while the
  combinations vary. The cost is one wrapper class per step and a
  composition root that wraps each object, and every wrapper must keep
  the wrapped object's promise. Rule 1 of [choosing composition over
  inheritance](../../oo-choosing-composition-over-inheritance/SKILL.md)
  reuses behaviour by holding the object and forwarding to it.

- **Proxy.** A lab report is expensive to load, or only some staff may
  open a patient record, and callers want the same messages either way.
  The force is a stand-in for the real object that delays, guards or
  records access. The cost is one class between every caller and the
  real object, plus the rule for when the real object is reached.

- **Facade.** Booking an appointment needs a schedule, a room planner, a
  dose stock and a letter queue, and every screen calls them in its own
  order. The force is one request for one clinic job over a complex
  subsystem. The cost is a class that can grow into a god class if it
  takes every request. Rule 2 of [hiding
  implementation](../../oo-hiding-implementation/SKILL.md) makes a class
  deep: a small interface over substantial work.

- **Bridge.** Reminders have a kind, text or email, and a purpose,
  appointment or recall, and both lists grow. The force is two
  dimensions that vary independently, so one hierarchy would multiply
  classes. The cost is two hierarchies and a reference from one to the
  other, which is more than a single class until both dimensions have
  evidence.

## Creating objects varies

- **Factory Method.** A class cannot know which object to create, such
  as an appointment for a first visit or a follow-up, and it leaves one
  creation step to its subclasses. The force is creation that varies
  with the subclass while the caller keeps one message. The cost is a
  subclass per product and a creation method that every subclass must
  override. A factory method is a creation method that a subclass
  overrides. It is not the static named factory that [constructing valid
  objects](../../oo-constructing-valid-objects/SKILL.md) rule 4 gives,
  and that `notation.md` defines as a `static` method returning
  `new ...`; that is a different arrangement with a similar name.

- **Abstract Factory.** A family of related objects, such as an
  appointment, an invoice and a reminder for one insurer, must match,
  and mixing families breaks a rule. The force is several products that
  vary together and must come from one family. The cost is a factory
  interface, one concrete factory per family and a product interface for
  each kind; it grows quickly when only one product varies.

- **Builder.** An appointment or a clinic site has many optional parts,
  such as a previous visit, an interpreter or equipment, and the
  constructor takes a long list. The force is many optional parts that
  are assembled before the object exists, with the required parts known
  up front. The cost is a builder class per product, a step per optional
  part and a build step that must check the whole; a builder for two
  fields costs more than it saves. Rule 5 of [constructing valid
  objects](../../oo-constructing-valid-objects/SKILL.md) uses a builder
  only when many parts are optional.

- **Prototype.** A new appointment or clinic template starts as a copy
  of an existing one with a few fields changed. The force is an object
  that must be copied without the caller knowing its concrete class, and
  copying is cheaper or safer than rebuilding. The cost is a copy method
  on every class in the family, plus the decision of which fields are
  shared and which are copied deeply.

## A group of objects is treated as one or walked

- **Composite.** A care plan or a set of appointment rules holds single
  items and groups of the same items, and callers treat the two
  differently. The force is a part and a whole that answer the same
  messages, so callers do not branch on the shape. The cost is one
  interface and a leaf and group class; a group must decide the order of
  its children and what one child's error does.

- **Iterator.** Different collections of appointments or slots expose
  their storage, and every caller writes its own walk. The force is a
  walk over a collection without the caller knowing its storage, with
  several walks active at once. The cost is an iterator object per walk
  and a decision about what a change during a walk means.

- **Visitor.** A fixed set of clinic items, such as a consultation, a
  procedure and a vaccination, gains a new operation every month, such
  as billing, room preparation or a report, and each class is edited
  again. The force is new operations that arrive more often than new
  kinds, where an operation needs the item's concrete kind. The cost is
  a visitor interface and an accept method on every element; a new kind
  edits every visitor.

- **Interpreter.** The clinic stores a small rule language, such as an
  eligibility expression or a reminder schedule, and the code parses and
  evaluates it in branches. The force is a small grammar that is
  evaluated and changes often. The cost is a class per grammar rule and
  a parser; an interpreter for two fixed rules is more machinery than a
  method.

## Objects are shared rather than made anew

- **Flyweight.** Many appointment rows each hold their own copy of the
  same room description or appointment-kind description, and memory or
  load time suffers. The force is many objects that share a large
  immutable part while the varying part is small. The cost is a cache or
  factory for the shared parts and a split between shared and per-object
  state, and every reader must know which part is shared.

- **Singleton.** A clinic clock, a configuration or a connection is
  needed from everywhere, and code reaches a global to get it. The force
  is exactly one instance that must be reachable. The cost is a global
  name, dependencies that are hidden from constructors, and tests that
  must reset shared state. The pack makes one instance at the
  composition root and passes it in through constructors instead, as
  rule 3 of [inverting
  dependencies](../../oo-inverting-dependencies/SKILL.md) asks.

## Objects react without knowing each other

- **Observer.** When an appointment is cancelled, several parts must
  react, such as releasing the slot and sending a letter, and, once the
  slot is free, offering it to the waiting list, and the cancelling code
  grows a step for each reaction.
  The force is one change with several reactions, where the changing
  object must not know each one. The cost is a list of listeners, a
  publication step and rules for order and failure; a reaction that must
  happen at once is harder to follow through a list. Rule 6 of
  [publishing domain
  events](../../oo-publishing-domain-events/SKILL.md) chooses an
  event when the change is complete without its reactions and the
  reactions vary or belong to other modules, and a direct message when
  the caller needs the outcome to finish.

- **Mediator.** A booking desk, a reminder job and a waiting list each
  talk to all the others, so one change edits many classes. The force is
  several colleagues that must coordinate while none knows all the
  others. The cost is a mediator that can become a god class and an
  indirection for every conversation.

- **Chain of Responsibility.** A request, such as a prior authorisation
  or a request for a second opinion, may be handled by a clinician, then
  a specialist, then an insurer, and the sender must not know which. The
  force is several handlers that may take a request in turn, with a set
  or order that varies. The cost is a handler interface and links
  between handlers; a request that no handler takes needs a decided
  answer, and a defect means following the chain.

## State is kept and restored

- **Memento.** A clinic form or an appointment must be restored
  exactly as it was, such as a half-finished intake form or a
  rescheduled appointment. The force is an object's state captured and
  restored without exposing its fields to the capturer. The cost is a
  snapshot value per save, a rule for how long snapshots live and a way
  for the object to rebuild itself from one; a large object makes each
  snapshot expensive.
