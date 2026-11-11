# Humble edges

A scheduled job is an edge the framework owns: it starts the job, hands
over its own run object and expects a return. The job is hard to test
without the framework, so keep it humble. It passes the one value the
work needs to an object that knows the clinic's rules. The
`FrameworkJob` and `JobRun` types stand for any framework's own types;
this skill names no framework.

```text
class NightlyReminders extends FrameworkJob
  - sendReminders: SendReminders
  + new(sendReminders: SendReminders)
  + execute(jobRun: JobRun): void
    sendReminders.run(jobRun.startedAt())

class SendReminders
  - appointments: Appointments
  - notices: Notices
  + new(appointments: Appointments, notices: Notices)
  + run(now: DateTime): void
    notices.remindAll(appointments.dueForReminder(now))
```

`Appointments` keeps the shape the repositories skill gives its port,
with `find` and `save`, and adds `dueForReminder(now)`, which answers
the appointments whose reminder is due at `now` and changes nothing.
`Notices` is the port in the aggregates reference that sends a patient
a message; this reference adds `remindAll`, which sends one reminder
per appointment and changes nothing in the aggregates. `startedAt()`
answers the time the framework started the job. The fence stores
nothing and leaves out how a sent reminder is recorded.

A test builds `SendReminders` with an in-memory `Appointments` port and
a `Notices` stand-in that records what it is sent, fixes `now`, and
runs `run`. It checks the reminders and the appointments due, with no
framework and no server. The job itself stays untested beyond its
wiring: one test builds it with a `SendReminders` stand-in and checks
that `execute` passes the started time. A screen and a message listener
are kept humble in the same way. The screen keeps the code that reads
its widgets and writes its fields; the listener keeps the code that
reads the message; each sends the decision to an object that a test can
call without the framework. Presentation patterns are outside this
skill.
