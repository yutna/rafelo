# Diff checklist

Ask these questions of the lines a change adds or alters, and of
nothing else. Each question names the rule that answers it; read the
rule in its skill before writing a finding.

## A new or changed class

- Does each behaviour sit with the object that holds the information it
  needs? [Assigning responsibilities][assigning], rule 1.
- Does the class change for one kind of request?
  [Assigning responsibilities][assigning], rule 7.
- Does its constructor leave it complete and valid?
  [Constructing valid objects][constructing], rule 1.
- Does it receive its collaborators through its constructor?
  [Inverting dependencies][inverting], rule 2.

## A new or changed method

- Does a caller ask for the object's state and decide for it?
  [Encapsulating state and behaviour][state-and-behaviour], rule 3.
- Does it hand out a collection the object keeps?
  [Encapsulating state and behaviour][state-and-behaviour], rule 5.
- Does a caller reach through one object to another's collaborators?
  [Limiting what an object knows][knows], rule 2.
- Does its name say the effect it has or the answer it gives?
  [Naming classes and methods][naming], rule 2.

## A new dependency

- Does it point inward, toward the domain?
  [Layering the system][layering], rule 1.
- Does domain code now name a database, a framework or a clock?
  [Inverting dependencies][inverting], rule 1.

## A new error or absent value

- Is a refusal raised as an error named in the clinic's words?
  [Designing failure behaviour][failure], rule 1.
- Can a value be absent where its type does not say so?
  [Designing failure behaviour][failure], rule 5.

## A new state, field or flag

- Can the fields hold a combination the clinic never allows?
  [Making illegal states impossible][illegal-states], rule 1.
- Can an object leave a final state?
  [Modeling lifecycles][lifecycles], rule 4.

## A new or changed test

- Does it go through the messages the object's callers send?
  [Testing object-oriented code][testing], rule 1.
- Does its name say the behaviour it checks, in the clinic's words?
  [Testing object-oriented code][testing], rule 3.

[assigning]: ../../oo-assigning-responsibilities/SKILL.md
[constructing]: ../../oo-constructing-valid-objects/SKILL.md
[failure]: ../../oo-designing-failure-behaviour/SKILL.md
[illegal-states]: ../../oo-making-illegal-states-impossible/SKILL.md
[inverting]: ../../oo-inverting-dependencies/SKILL.md
[knows]: ../../oo-limiting-what-an-object-knows/SKILL.md
[layering]: ../../oo-layering-the-system/SKILL.md
[lifecycles]: ../../oo-modeling-lifecycles/SKILL.md
[naming]: ../../oo-naming-classes-and-methods/SKILL.md
[state-and-behaviour]: ../../oo-encapsulating-state-and-behaviour/SKILL.md
[testing]: ../../oo-testing-object-oriented-code/SKILL.md
