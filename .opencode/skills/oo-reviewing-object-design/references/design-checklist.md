# Design checklist

Ask these questions of a new module, context or system before its code
is written, in the order of the index's design loop. Each question
names the rule that answers it.

1. Is the rule the design must keep written down, with one example it
   accepts and one it rejects? [The index's gate][gate].
2. Does each behaviour sit with the object that holds the information
   it needs? [Assigning responsibilities][assigning], rule 1.
3. Is each aggregate drawn around the objects that one rule keeps true
   at every change? [Designing aggregates][aggregates], rule 1.
4. Does an operation that no single aggregate can decide sit in a
   domain service? [Placing domain logic][placing], rule 3.
5. Does every value a type allows match a state the clinic allows?
   [Making illegal states impossible][illegal-states], rule 1.
6. Does the domain name the messages it needs, with adapters behind
   them for the database and the framework?
   [Inverting dependencies][inverting], rule 1.
7. Do the names of classes, methods and events use the staff's words?
   [Speaking the domain language][domain-language], rule 1.
8. Does every value a test cannot repeat, such as the current time,
   arrive through a port? [Designing for testability][testability],
   rule 2.

[aggregates]: ../../oo-designing-aggregates/SKILL.md
[assigning]: ../../oo-assigning-responsibilities/SKILL.md
[domain-language]: ../../oo-speaking-the-domain-language/SKILL.md
[gate]: ../../oo-design/SKILL.md#before-designing
[illegal-states]: ../../oo-making-illegal-states-impossible/SKILL.md
[inverting]: ../../oo-inverting-dependencies/SKILL.md
[placing]: ../../oo-placing-domain-logic/SKILL.md
[testability]: ../../oo-designing-for-testability/SKILL.md
