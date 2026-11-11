# Where Each Borrowing Lives

Four techniques that functional programming made common answer problems
that object code meets. This skill owns two of them; the other two
belong to the skills named here, and this file only points to them.

- **Hidden mutation.** A helper changes data its caller handed it. Rule
  2 of this skill bars it; modeling values and entities, rule 2, makes a
  value immutable, and encapsulating state and behaviour, rule 6, copies
  a mutable input or output at an object's boundary.
- **A decision tangled with its effects.** A test needs stand-ins for
  the store and the sender to check one decision. Rules 1 and 3 of this
  skill make the decision pure and put it inside a shell; designing for
  testability, rule 6, splits a decision from its effect inside one
  class.
- **A class that carries one function.** An interface with one method,
  and a class for each case, for behaviour with no state and no name the
  staff use. Patterns the language provides, rules 1 to 3, pass a
  function value instead.
- **Operations that keep arriving.** A hierarchy where each new
  operation edits every class. Replacing conditionals with polymorphism,
  rule 7, chooses a closed set of cases with exhaustive matching when
  new operations arrive more often than new kinds.

Rule 4 keeps each borrowing inside the module's idiom: none of them
turns an object-oriented module into a second architecture.
