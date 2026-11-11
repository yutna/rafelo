# Test names and shape

A test has three parts, in this order: what it builds, the one message
it sends, and what it checks. Write them in that order, so a reader
follows the test once and sees the same story a caller lives through.

- **Build.** Make the objects the behaviour needs: the real domain
  objects, such as the patient and the slot for a booking, put in their
  starting state with their own messages, such as `join` for a waiting
  list, and a stand-in for each port the object reaches.
- **Send.** Send one message, the one whose behaviour the test's name
  states. A second message after it, outside the build, hides which
  send the test is about.
- **Check.** Check what a caller could observe, as rule 1 asks: an
  answer, a later answer from a public message, or a message that
  leaves through a port.

One behaviour per test means one failure names one broken rule. A test
may check more than one outcome of the behaviour its name states, as
the Pattern's test checks both the notice and the waiting list. When a
test checks two behaviours, a red run says only that something in it
broke, not which rule. Split it, and give each part the name it earns.

Names use the clinic's words and state the situation and the outcome.
The table pairs three names that do with three that say nothing about
the behaviour.

|Good name|Poor name|
|---|---|
|a diet plan cannot be issued before the visit ends|test1|
|an equipment loan is refused while the same pump is out|loanPump|
|a specimen label is refused when the patient has no order|labelWorks|

`test1` counts tests and says nothing about any of them. `loanPump` and
`labelWorks` name a method, or a thing that works, rather than the
behaviour. A reader who has never opened the class can tell from the
good name what broke and what to look at next.

A test-first step reads in three moves. First write the test and run it;
it fails, and the failure names the reason the test's name gives. Then
write the least code that makes it pass, which may be one rough line in
one method. Then improve the design while every test stays green, so the
tests hold the behaviour in place through the change. Rule 2 states the
step; this note is how it runs in a clinic change.
