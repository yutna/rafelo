# Comments Worth Keeping

Rule 2 keeps a comment that says why. This file lists the kinds of
comment worth keeping and the kinds to delete, then walks through one
cleanup.

## Kinds worth keeping

- **A reason.** Why the code takes the longer road when a shorter one
  looks right: "a second request here would book the room twice".
- **An outside constraint.** What another system or organisation
  demands, which no name in the clinic's code can carry: "the payer
  refuses a claim sent on the day of the visit".
- **A trade-off.** What the team gave up, and why: "a full reload is
  slower, but the partial one missed cancelled slots".
- **A warning.** A consequence a reader would not expect: "running this
  twice sends the patient two letters".
- **A contract.** Under a public method's signature, what callers may
  rely on, where honouring substitutability, rule 4, asks for one.

## Kinds to delete

- A comment that says what the next line does.
- A comment that names what the code names, such as "the constructor".
- A comment that tells who changed a line and when, or what it
  replaced: version control keeps that, as rule 5 says.
- Code that is commented out: version control keeps it too.
- A comment that disagrees with the code, once rule 3 has found which
  one is right and corrected the other.

## A worked cleanup

A clinic class that sends patients a questionnaire to fill in before a
first visit holds four comments.

1. "Sends the questionnaire", above `sendQuestionnaire`: it repeats the
   name, so it is deleted (rule 4).
2. "Only for patients over sixty", above a line that sends the
   questionnaire to every new patient: it disagrees with the code. The
   nurses who own the questionnaire confirm that every new patient gets
   it, so the comment is wrong. Corrected, it would only repeat the
   line, so it is deleted, and a test named "every new patient is sent
   the questionnaire" now carries the rule (rules 3 and 6).
3. A block that lists who changed the class over two years: deleted,
   because version control keeps it (rule 5).
4. "The questionnaire service deletes a link it has not seen used
   within a week": an outside constraint the code cannot show, so it
   stays (rule 2).

The cleanup ends with one comment in the class, and that comment says
why, as rule 2 asks.
