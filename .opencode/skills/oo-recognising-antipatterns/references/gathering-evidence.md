# Gathering evidence

A smell is a place to look. Evidence from the code or its history turns
it into a finding, and the same sources that confirm one antipattern
often clear another.

## Where evidence comes from

- **The change history.** How often a file changes, and which files
  change together, confirms a god class when one class is edited by most
  requests, for unrelated reasons, and confirms shotgun surgery when one
  request touches the same scattered files each time.
- **Who calls what.** The call graph confirms lava flow when nothing
  calls the code, and clears it when a caller still sends the message.
  It confirms a poltergeist when one caller creates the class for a
  single message and drops it, and clears a poltergeist when the class
  is the use-case object a user interface or an API calls first, which
  assigning responsibilities, rule 5, asks for. It clears an anemic
  model when no outside code reads the class's fields to decide with
  them, so no rule is left without a home.
- **What runs in production, from counters or traces.** A counter that
  never moves and a trace with no entry confirm lava flow; a counter or
  trace that shows the code reached clears it.
- **What each test must set up or reset.** A test that resets one
  instance before every case confirms a single instance reached from
  anywhere; a test that builds the collaborators it needs clears it.

## A worked review

The reminders module came back from a review with a list of smells:
`ReminderJob`, a class that builds a reminder, chooses its words, sends
it and retries; `PatientFile`, a long class of fields with getters and
setters; `ReminderClock`, read from a static field in fourteen classes;
`ReminderDispatch`, created inside `ReminderJob.run` to send one message
to `TextFormatter`; `FaxSender`, kept after the clinic stopped sending
faxes; a reminders module and a patient-file module that import each
other; and `FormatterFactory`, which now builds one formatter. The
review also listed the copy changes, which keep editing `ReminderText`,
`PatientFile` and the gateway adapter together.

The change history covered sixty requests in a year. `ReminderJob`
changed in forty-one of them, for four unrelated reasons. That is a
finding: a god class, and the first one to fix. Nine of the sixty were
copy changes, and each edited the same three files. That is a finding:
shotgun surgery, second. `ReminderClock` changed seven times, and every
test resets it. That is a finding: a single instance reached from
anywhere. `ReminderDispatch` changed four times, holds no field of its
own and lives for one message. That is a finding: a poltergeist. The
import graph shows reminders and patient files needing each other, and
three changes touched both directions. That is a finding: a dependency
cycle. `FormatterFactory` has had two changes since the second formatter
was removed, and no request needs another formatter. That is a finding: a
pattern with no force. `FaxSender` has not changed in thirty months, no
trace shows it reached and no test covers it. That is a finding: lava
flow, and it comes last because no change needs it.

Two items stay places to look. `PatientFile` is long, but no service
decides with its fields and no change this year needed a rule outside it,
so no rule is homeless. `ReminderText.format` is a long method, but it
changes only when the clinic changes its wording, and no other class
decides with what it holds. The findings above are ordered by how often
their code changed, because that is where a change pays for the fix.
