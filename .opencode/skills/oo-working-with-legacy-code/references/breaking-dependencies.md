# Breaking dependencies

Rule 2 allows three small edits that remove what stands between a test
and a class. None of them moves logic, and none of them introduces a
subclass only so a test can replace a method. Take one edit at a time,
and check each one by reading the change, building the program and
running whatever tests exist.

- **Passing a collaborator into the constructor.** This fits when the
  constructor builds a concrete collaborator that a test cannot
  control, such as `StatementRun` building its own `StatementPrinter`.
  Add a constructor parameter for the collaborator, assign it to the
  field and delete the construction inside. Read the diff to confirm
  that no other method body changes and that the constructor only stops
  building the collaborator it now receives; build the program and run
  the tests. Where every caller cannot change in the same edit, keep
  the old way of building the class in one named factory that passes
  the real collaborator. That factory holds a break that already
  existed in one place, adds none, and goes once every caller builds
  the class at the composition root, as inverting dependencies, rule 3,
  asks. It is a place to stand for a time, not a pattern to copy.

- **Pulling an interface the class owns out of a concrete class.** This
  fits when the class sends messages to a concrete class whose answers
  a test cannot choose, such as `PermitIssuer` asking a
  `CarParkRegister` for free spaces. Declare an interface for only the
  messages the class sends, let the concrete class implement it without
  changing its body, and hold the interface in a field the constructor
  sets, with the named factory of the first edit where callers cannot
  all change. Read the interface and list every message against the
  class's sends; build the program and run the tests. No method body
  moves, and the concrete class keeps its behaviour.

- **Moving a static call behind a method of an object the class
  receives.** This fits when code reaches an outside system through a
  static call, such as `DoseLabel` sending a line to
  `LabelPrinter.print(line)`. Add a small object behind an interface the
  class owns, whose method sends the same static call once, pass that
  object into the constructor, and replace the static call in the class
  with a message to the new object. Read the change to confirm that the
  argument and the answer are untouched; build the program and run the
  tests. The static call remains in the new object, where a test can
  replace the whole object instead of the call.

If an edit begins to move a branch or change a return value, stop. That
is logic moving, and rule 2 does not allow it until a test covers the
class. Put the tempting cleanup in a note and return to the dependency.
