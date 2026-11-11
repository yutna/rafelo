# What Changed

Object-oriented design kept its core ideas while the advice around them
shifted. Each shift below names the rules in this pack that carry it.

- **Inheritance became a special tool, and composition the usual
  one.** A class reuses behaviour by holding an object that has it, and
  extends another class only as a subtype that is usable wherever its
  parent is expected.
  [Choosing composition over inheritance][composition], rules 1 and 2;
  [honouring substitutability][substitutability], rule 1.
- **Immutability became the default.** A value never changes after it
  is built, and the language's own records, value types and closed sets
  of cases carry much of the work.
  [Modeling values and entities][values], rule 2;
  [deciding object or data][object-or-data], rule 4;
  [making illegal states impossible][illegal-states], rule 2.
- **Many patterns became features of the language.** A function value
  replaces a strategy with one operation, no state and no name the
  staff use, and the language's own iteration replaces an iterator
  class.
  [Patterns the language provides][language-patterns], rules 1 and 4.
- **Plain constructors came back.** Each object receives its
  collaborators through its constructor, and the program is wired by
  hand in one place; a container is kept for the objects a framework
  builds itself.
  [Inverting dependencies][inverting], rules 2, 3 and 4;
  [patterns the language provides][language-patterns], rule 6.
- **Many stand-ins in a test became a sign about the design.** A test
  that needs many stand-ins to check one decision points at a design
  that mixes the decision with its effects.
  [Designing for testability][testability], rules 1 and 6;
  [testing object-oriented code][testing], rule 4.
- **The argument over anemic models narrowed to one question.** A model
  is at fault when a business rule has no home, not when a class has no
  methods.
  [Deciding object or data][object-or-data], rules 1 and 2.
- **Module boundaries follow the model's words.** A boundary goes where
  words change meaning and where a business capability ends, not where
  a class hierarchy splits.
  [Bounding contexts][contexts], rule 1;
  [organising modules][modules], rule 1.

[composition]: ../../oo-choosing-composition-over-inheritance/SKILL.md
[contexts]: ../../oo-bounding-contexts/SKILL.md
[illegal-states]: ../../oo-making-illegal-states-impossible/SKILL.md
[inverting]: ../../oo-inverting-dependencies/SKILL.md
[language-patterns]: ../../oo-patterns-the-language-provides/SKILL.md
[modules]: ../../oo-organising-modules/SKILL.md
[object-or-data]: ../../oo-deciding-object-or-data/SKILL.md
[substitutability]: ../../oo-honouring-substitutability/SKILL.md
[testability]: ../../oo-designing-for-testability/SKILL.md
[testing]: ../../oo-testing-object-oriented-code/SKILL.md
[values]: ../../oo-modeling-values-and-entities/SKILL.md
