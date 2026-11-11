# Fragile hierarchies

- [The fragile base class](#the-fragile-base-class)
- [The yo-yo](#the-yo-yo)
- [One class holding its collaborators](#one-class-holding-its-collaborators)
- [When a mixin is safe](#when-a-mixin-is-safe)

A hierarchy ties a subclass to the way its parent is written, not only to
the messages the parent offers. This reference follows one reminder
through a three-level hierarchy, then rebuilds the same senders as one
class with two collaborators. It ends with the two kinds of mixin: one
that uses only public messages, and one that reaches into its host.

## The fragile base class

The clinic sends appointment reminders. The top sender fixes the order:
format the reminder, then deliver the message. Each step is a method the
top sends to itself, so a subclass can replace either one.

```text
value Reminder
  - patient: PatientId
  - text: String
  + new(patient: PatientId, text: String)
  + text(): String
    return text

interface ReminderChannel
  + deliver(reminder: Reminder, message: String): void

class ReminderSender
  + send(reminder: Reminder): void
    message := format(reminder)
    deliver(reminder, message)
    return
  + format(reminder: Reminder): String
    return reminder.text()
  + deliver(reminder: Reminder, message: String): void
    return

class SignedReminderSender extends ReminderSender
  + format(reminder: Reminder): String
    return super.format(reminder).followedBy(signature())
  - signature(): String
    return "the clinic"

class ChannelReminderSender extends SignedReminderSender
  - channel: ReminderChannel
  + new(channel: ReminderChannel)
  + deliver(reminder: Reminder, message: String): void
    channel.deliver(reminder, message)
    return
```

`followedBy` is taken to mean the text of the receiver followed by
the text of its argument, and `"the clinic"` is taken to mean
that signature text. The top `deliver` has an empty body, so the top and
middle classes cannot deliver on their own; only the bottom class gives
that step a body. `channel` is set by the bottom class's constructor
before `deliver` reads it, and no other class in the hierarchy declares a
field. For one `send`, the message is formatted once and the channel
delivers once.

The base class is fragile because `send` decides which of its own methods
run. If the top's author replaces `format(reminder)` with
`reminder.text()` to save a call, `SignedReminderSender.format` never
runs and every signature disappears. No subclass code changes, and a
test that sends only a subclass's `format` still passes. A test that
sends `send` to a subclass and checks the signature fails, and that
failing test is the evidence the red flags ask for. The subclasses
depended on an internal send, which is the coupling this skill warns
about.

## The yo-yo

Follow one `send` on a `ChannelReminderSender`, from the outside in.

1. `send` is not overridden, so `ReminderSender.send`, the top class,
   runs. It sends `format(reminder)` to the object itself.
2. The override in `SignedReminderSender`, the middle class, runs. It
   sends `super.format(reminder)` to the top, which returns the
   reminder's text, then appends the signature.
3. Back in the top's `send`, it sends `deliver(reminder, message)` to the
   object itself. The override in `ChannelReminderSender`, the bottom
   class, runs. It sends the message through its channel once.
   `ReminderSender.deliver` does not run, because the bottom override
   replaces it.

So one `send` runs code in three classes, and the reader has to move up
and down the hierarchy to see it. `format` runs in the middle and top;
`deliver` runs in the bottom only. That up-and-down reading is the yo-yo,
and it is the cost a hierarchy must repay with a real kind-of
relationship.

## One class holding its collaborators

The same senders become one class that holds a formatter and a channel.
The formatter decides the text; the channel decides how it leaves the
clinic. Neither is a parent, so neither can change what the sender does
by changing an internal send.

```text
value Reminder
  - patient: PatientId
  - text: String
  + new(patient: PatientId, text: String)
  + text(): String
    return text

interface ReminderFormatter
  + format(reminder: Reminder): String

interface ReminderChannel
  + deliver(reminder: Reminder, message: String): void

class ReminderSender
  - formatter: ReminderFormatter
  - channel: ReminderChannel
  + new(formatter: ReminderFormatter, channel: ReminderChannel)
  + send(reminder: Reminder): void
    message := formatter.format(reminder)
    channel.deliver(reminder, message)
    return
```

A `SignedFormatter` implements `ReminderFormatter` and returns the text
with the signature; a `ClinicChannel` implements `ReminderChannel` and
sends the message. The sender's constructor sets both fields before
`send` reads them, and `send` asks each collaborator once. To follow one
send, a reader opens the sender and the two interfaces. The sender
offers no `format` and no `deliver`, so a subclass cannot override a step
the sender did not mean to expose.

## When a mixin is safe

A mixin adds behaviour to several classes without a parent. It is safe
when it uses only messages its host already offers in public. An ordering
built from a comparison the host defines is the usual example: the mixin
sends the host's comparison message, holds no state, and reads no field.
Every host that offers the comparison can use it, and a host that changes
a private field cannot break it.

A mixin is not safe when it reads or writes its host's fields. A mixin
that sets a status field, or reads the patient on a slot directly,
depends on the host's private shape. A host that renames the field or
adds a rule about it breaks the mixin, and the mixin can put the host
into a state its own methods forbid. The fix is the same as the sender:
give the behaviour to an object the host holds, and let the host forward
only the messages it means to offer.
