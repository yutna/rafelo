# Stand-ins

A stand-in is what the pattern index calls a Test Double: an object a
test hands a collaborator's place to. The five kinds differ in what the
test gives them and what it reads back from them afterwards.

- **Dummy.** The test hands it nothing and reads nothing back; its only
  job is to fill a parameter the test never uses. A test of a refused
  booking, on which the use case sends no notice, passes a dummy for the
  notices port, so the constructor still receives every collaborator.
- **Stub.** The test hands it one answer it chose, and reads nothing
  back. A test of a reminder rule gives the clock port a stub that
  answers a fixed time, so the rule fires when the test intends.
- **Spy.** The test hands it nothing and reads, after the act, the
  commands it recorded. A test of the freed-time step passes a spy for
  the notices port and checks which patient it was asked to tell.
- **Mock.** The test hands it the commands it expects before the act,
  and reads nothing back; the mock fails the test itself at the moment
  a different command arrives. A test of the freed-time step tells a
  mock for the notices port to expect one `send` for the patient, and
  the mock fails the test when it does not arrive.
- **Fake.** The test hands it the data it works on and reads through it
  as a caller would. A repository fake keeps the aggregates in memory,
  so a use case can add and find one without a database.

Whether the test hears about a command during the act or after it
chooses between the mock and the spy. A spy records every command and
lets the test check after the act, so the test reads as one story:
build, send, check. A mock is given the expectation before the act and
fails at the moment an unexpected command arrives, so the expectation
sits at the top of the test. Both check a command; neither checks a
query.

A query gets a stub and is never checked, because a query changes
nothing, as rule 4 of [encapsulating state and
behaviour](../../oo-encapsulating-state-and-behaviour/SKILL.md) asks.
Whether or how often it is asked is not behaviour a caller can see; the
test needs the answer, not a record of the asking. Hand the collaborator
a stub that carries the answer, then check the outcome the answer led to.

A fake is checked by the same tests as the adapter it stands in for, as
rule 7 asks. Run the adapter against the real outside system in a few
slower tests, run the fake through the same test body, and a difference
between them shows as a failure instead of as a test that passes for the
wrong reason.
