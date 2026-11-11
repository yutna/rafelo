# Antipatterns and their rules

An antipattern is a smell that the evidence has confirmed as a finding.
The evidence comes from the code or its history, and the rule it breaks
decides who fixes it: the skill that owns that rule, not this one. Each
item below names the smell, the evidence that makes it a finding, and
the rule it breaks.

- **God class.** One class knows and does too much, so most change
  requests touch it for reasons that do not belong together. The change
  history is the evidence: the same class edited by unrelated requests.
  It breaks [assigning
  responsibilities](../../oo-assigning-responsibilities/SKILL.md), rules
  7 and 8.

- **Anemic model.** A class holds only fields and their accessors while
  the rules that decide with those fields live somewhere else. The
  evidence is a service or controller that reads the fields and decides
  with them, so the class changes only when its data shape changes. It
  breaks [deciding object or
  data](../../oo-deciding-object-or-data/SKILL.md), rule 1.

- **A single instance reached from anywhere.** One instance of a class is
  reached through a global or a static field by every caller that needs
  it. The evidence is a constructor that does not name the collaborators
  the object uses, and tests that must reset the instance before each
  one. It breaks [inverting
  dependencies](../../oo-inverting-dependencies/SKILL.md), rules 2 and 3.

- **Poltergeist.** A short-lived class with no state of its own is
  created only to start another object's work and is then dropped. The
  evidence is a class with no field of its own that lives for one
  message and only forwards it; removing it moves no rule. It breaks
  [this skill](../SKILL.md), rule 4.

- **Lava flow.** Code that nobody understands, nobody calls on purpose
  and nobody dares delete keeps its place in the module. The evidence is
  a year with no run reaching it, no test covering it, and no change
  request that needs it. It breaks [this skill](../SKILL.md), rule 3.

- **Dependency cycle.** Two modules need each other, directly or through
  a third, so neither can be built, tested or released alone. The
  evidence is the import or build graph showing a path from each module
  to the other. It breaks [organising
  modules](../../oo-organising-modules/SKILL.md), rule 4.

- **Service locator.** An object asks a global registry for its
  collaborators instead of receiving them. The evidence is a constructor
  that does not name what the object uses, and a test that must fill the
  registry before it can check a rule. It breaks [inverting
  dependencies](../../oo-inverting-dependencies/SKILL.md), rule 5.

- **A pattern with no force.** A pattern stays in the code after the
  force it answered has gone, such as a factory that builds one type or
  a strategy with one implementation left. The evidence is no second
  case, no change that keeps coming back and no duplication that has
  drifted apart. It breaks [choosing a
  pattern](../../oo-choosing-a-pattern/SKILL.md), rules 2 and 6.

- **Shotgun surgery.** One business change edits many modules, and the
  next change to the same rule edits the same scattered files again. The
  evidence is the change history: one request touching the same set of
  files each time it comes. It breaks [diagnosing
  coupling](../../oo-diagnosing-coupling/SKILL.md), rule 1, which names
  the tie first, and then [hiding
  implementation](../../oo-hiding-implementation/SKILL.md), rule 5,
  which keeps the decision in one module.
