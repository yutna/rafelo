# Framework Pressures

Each pressure below is something a framework asks of the code, with
what to accept and what never to accept. Rule 2 settles a demand by
meeting it in a class at the edge, or, for a base class, by its
active-record exception, and rule 3 weighs the demands it leaves open.
The "never" side of each names the rule that no framework excuses.

- **A mapper's base class.** The mapper saves only objects that extend
  its base class. Accept, under rule 2: the base class on a row class
  at the edge, converted to and from the domain object in the adapter,
  as taming persistence, rule 2, keeps every mapping decision there;
  or, in a module that taming persistence, rule 1, puts on active
  records, the base class on the module's own classes. Never: a
  business rule moved into a save hook or a callback, or a domain
  object that can be stored in a state the clinic forbids (rule 1).
- **A form binder.** The binder fills objects through a constructor
  with no arguments and a setter for each field. Accept, under rule 2:
  a form object at the edge that the binder fills, and that turns its
  text into values once, as placing domain logic, rule 5, asks. Never:
  a domain object that the binder fills field by field, so that it
  exists half-built between two setters, which constructing valid
  objects, rules 1 and 2, forbid.
- **A container.** The framework builds some objects itself, such as
  request handlers, and wires them from markers on their classes. The
  markers are read on rule 2's edge class; the container that reads
  them is rule 3's. Accept: the container for the objects the framework
  builds, given the choices the composition root made, as inverting
  dependencies, rule 4's exception, allows. Never: a domain class that
  asks the container for a collaborator, which inverting dependencies,
  rule 5, forbids.
- **Validation markers.** The framework checks the shape of a request
  from markers on a transfer type's fields. Accept, under rule 2: the
  markers on the transfer type at the edge, for what is well formed.
  Never: the domain trusting the transfer type without converting it
  into its own types first, as deciding object or data, rule 3, asks.
- **Lazy loading.** The mapper loads an association when it is first
  touched. Accept, under rule 3: the mapper keeps the feature. Never:
  a lazy load that crosses an aggregate's boundary or outlives its
  transaction, so that a domain method works only while the session is
  open, which taming persistence, rule 5, forbids.
- **A base class for request handlers.** The framework calls only
  classes that extend its handler class. Accept, under rule 2: a thin
  handler at the edge that turns the request into values and sends one
  message to a use-case object, as assigning responsibilities, rule 5,
  asks. Never: the use case's logic written in the handler.

## A worked weighing

A clinic team's framework saves only classes that extend its record
class, and runs a hook before each save. The team meets the first
demand at the edge and refuses the second.

1. The record class: it touches only the classes the mapper saves. The
   team puts it on a row class at the edge, converts each row to the
   domain object in one adapter, and records that choice once, as rule
   4 asks.
2. The save hook: a developer proposes to flag high home readings for
   review in it. That would move a rule into the framework, so the team
   refuses it, and the reading answers whether it needs review from the
   moment it is built (rule 1).

The work ends with the record class on the row at the edge and the save
hook refused, so the review rule stays in the domain (rule 1).
