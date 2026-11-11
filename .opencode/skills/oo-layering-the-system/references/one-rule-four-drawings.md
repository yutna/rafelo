# One rule, four drawings

Layered, hexagonal, onion and clean are four drawings of one
arrangement: source dependencies point inward, and code at the centre
knows nothing about the code that reaches it. The names below are
vocabulary, not rivals. A team picks the drawing it finds easiest to
talk about, then keeps the dependency rule.

|Drawing|Centre|Rings|Use cases|Ports|
|---|---|---|---|---|
|layered|The domain|Domain, application, adapters|Application ring|Inner ring|
|hexagonal|The domain|Inside and outside|Application ring|On boundary|
|onion|The domain model|Model, services, adapters|Application ring|Inner ring|
|clean|The entities|Entities, use cases, adapters|Use-case ring|Inner ring|

The layered drawing names its rings most plainly. The domain sits at
the centre, the application ring holds one object per use case, and the
adapters ring holds screens, web handlers, jobs and stores. The
hexagonal drawing, also called ports and adapters, draws one inside and
one outside around the domain. The inside holds the domain and the
application ring; the outside holds adapters that drive the application,
such as a screen, a job or a message listener, and adapters the
application drives, such as a store or a mail service. Its ports sit on
the boundary and are declared inside.

The onion drawing nests the domain model inside domain services, then
application services, then adapters. Its application services ring holds
the use cases, and each crossing outward is a port declared in an inner
ring. The clean drawing names four rings: entities at the centre, then
use cases, then interface adapters, then frameworks and drivers. Its
use-case ring holds one object per operation, and its ports are declared
inside and implemented in the interface-adapter ring. The outer ring
also holds the frameworks and drivers that the interface adapters keep
away from the inner code.

## The one dependency rule

All four keep the same rule: an inner ring never imports an outer one,
and an outer ring may import any inner one. The application ring may
call the domain, an adapter may call both, and the composition root may
call all of them. The reverse arrow is always a port declared by the
inner code and implemented by an outer adapter. The drawing changes the
names of the rings, the number of rings, and the shape of the picture,
never the direction of a source dependency.

## The old drawing, turned around

An older layered drawing put the data layer at the bottom and let the
domain import it. The domain called a database class to save an
appointment, so a change of store reached the business rules, and a
test of booking needed the store running. A port declared in the domain
turns that arrow around. The domain names `WaitingLists`, the database
adapter outside implements it, and the domain imports nothing from the
adapter. What was a call from the domain down to the data layer is now
a message the domain sends to its own port. The port belongs beside the
domain because the domain declares what it needs, not what the store
happens to offer.

## Strict layers, and the one skip

Strict layering lets a ring call only the ring directly inside it: an
adapter calls the application, never the domain. Relaxed layering lets
any ring call any inner ring, so an adapter may call a use case and,
where no rule is involved, a domain query. In this pack, every change
goes through a use case (rule 2), a read that decides nothing may go to
a read query instead (rule 6), and no adapter calls a domain object
directly. A change never skips the use case: it loads, sends the domain
its commands, stores and sets the transaction.
