# Three ways to organise

- [The module](#the-module)
- [As a transaction script](#as-a-transaction-script)
- [As a domain model](#as-a-domain-model)
- [As a table module](#as-a-table-module)
- [What a second rule costs](#what-a-second-rule-costs)
- [Signs a module has outgrown scripts](#signs-a-module-has-outgrown-scripts)
- [Moving one use case at a time](#moving-one-use-case-at-a-time)

A patient's preferred language and consent choices form one small
module: the clinic records the language the patient wants to be written
to in, and which contact channels the patient consents to. The same
module can be a transaction script, a domain model or a table module.
Each version below answers the same two requests, and the later sections
show what changes when a second rule arrives.

## The module

The clinic records two things for a patient: a preferred language and a
consent choice for each contact channel, such as text, email or post. A
second rule arrives later: a patient may be contacted by a channel only
when the language has a template for that channel and the patient's
latest choice for that channel allows contact. A reminder request and a
recall request both need that answer.

`Language` is taken to be the clinic's language value, and
`hasTemplateFor(channel)` is taken to answer whether the clinic writes
that channel's message in that language. `ContactChannel` is a type only;
`ConsentChoice` is the two-member enumeration the first fence declares.
`ChannelChoice` is the value the domain-model fence declares: one channel
paired with the patient's choice for it. `new List<ChannelChoice>()` is
taken to mean an empty list the object owns.

## As a transaction script

A transaction script gives each request one procedure, and the
procedures share a data-access object that reads and writes the store.

```text
enum ConsentChoice
  Allowed
  Refused

class PatientPreferences
  + languageOf(patient: PatientId): Language
  + recordLanguage(patient: PatientId, language: Language): void
  + choiceOf(patient: PatientId, channel: ContactChannel): ConsentChoice
  + recordChoice(patient: PatientId, channel: ContactChannel,
      choice: ConsentChoice): void

class RecordPreferredLanguage
  - preferences: PatientPreferences
  + new(preferences: PatientPreferences)
  + run(patient: PatientId, language: Language): void
    preferences.recordLanguage(patient, language)
    return

class RecordConsentChoice
  - preferences: PatientPreferences
  + new(preferences: PatientPreferences)
  + run(patient: PatientId, channel: ContactChannel,
      choice: ConsentChoice): void
    preferences.recordChoice(patient, channel, choice)
    return
```

`PatientPreferences` is the data-access object the scripts share;
`recordLanguage` writes one patient's language and `recordChoice` writes
one choice for one patient and one channel. What `RecordPreferredLanguage`
stores is one language value for one patient, and what
`RecordConsentChoice` stores is one choice for one patient and channel,
both in the preference store. Each script opens a transaction around its
one store message and ends it; the fence leaves the store and those
boundaries out.

Each request is one procedure with one store message. The two rules are
independent at this point, so a script per request is enough.

## As a domain model

A domain model gives the patient's values and their rules one object.
The object answers the contact question that both requests need.

```text
value ChannelChoice
  - channel: ContactChannel
  - choice: ConsentChoice
  + new(channel: ContactChannel, choice: ConsentChoice)

class PatientContact
  - patient: PatientId
  - preferredLanguage: Language
  - choices: List<ChannelChoice>
  + new(patient: PatientId, preferredLanguage: Language)
    choices := new List<ChannelChoice>()
  + prefer(language: Language): void
    preferredLanguage := language
    return
  + record(channel: ContactChannel, choice: ConsentChoice): void
    choices.add(new ChannelChoice(channel, choice))
    return
  + mayBeContactedBy(channel: ContactChannel): Boolean
    if preferredLanguage.hasTemplateFor(channel) then
      return choices.allowContactBy(channel)
    else
      return false
```

The constructor sets `patient` and `preferredLanguage` from its
parameters and starts `choices` as an empty list. `prefer` replaces the
language and `record` appends one `ChannelChoice`, which pairs the
channel with the patient's choice for it.
`choices.allowContactBy(channel)` is taken to answer whether the latest
`ChannelChoice` recorded for that channel allows contact, and `false` is
taken to be the no answer of a `Boolean`. `mayBeContactedBy` reads the
language and the choices, so the rule that depends on them has one home.

The fence changes the patient's contact object in memory. When a use case
stores it, what is stored is the whole `PatientContact`, in its
repository, in the transaction the application service opens and ends;
the store finds one contact by the patient's identity, and the fence
leaves the repository and those boundaries out.

## As a table module

A table module gives the table one class, and each method finds a row and
acts on it. The row's fields are open data.

```text
class PreferenceRow
  + patient: PatientId
  + language: Language
  + choices: List<ChannelChoice>
  + new(patient: PatientId, language: Language)
    choices := new List<ChannelChoice>()

class PatientPreferenceTable
  - rows: List<PreferenceRow>
  + new(rows: List<PreferenceRow>)
  + recordLanguage(patient: PatientId, language: Language): void
    row := rows.rowFor(patient)
    row.language := language
    return
  + recordChoice(patient: PatientId, channel: ContactChannel,
      choice: ConsentChoice): void
    row := rows.rowFor(patient)
    row.choices.add(new ChannelChoice(channel, choice))
    return
  + mayBeContactedBy(patient: PatientId,
      channel: ContactChannel): Boolean
    row := rows.rowFor(patient)
    if row.language.hasTemplateFor(channel) then
      return row.choices.allowContactBy(channel)
    else
      return false
```

`rows.rowFor(patient)` is taken to answer the preference table's row for
that patient. `PreferenceRow`'s constructor sets `patient` and `language`
from its parameters and starts `choices` as an empty list.
`recordLanguage` and `recordChoice` change one row directly;
`recordChoice` adds one `ChannelChoice`, so a row keeps each channel
beside its choice. `mayBeContactedBy` runs the contact check, which the
other two methods do not need, and sends `allowContactBy` to the row's
list just as the domain model does. The table module suits a bulk load
or a report that works over every row at once.

What `recordLanguage` and `recordChoice` store is one row of the
preference table, in the table's store, in the transaction the caller
opened; the fence leaves the store and those boundaries out.

## What a second rule costs

The contact rule is the second rule. It needs the language and the
choice together, and two requests, the reminder and the recall, both ask
it. In the script version, each request grows its own copy of the check.

```text
class SendReminder
  - preferences: PatientPreferences
  + new(preferences: PatientPreferences)
  + run(patient: PatientId, channel: ContactChannel): void
    raises ContactNotAllowed
    language := preferences.languageOf(patient)
    choice := preferences.choiceOf(patient, channel)
    if language.hasTemplateFor(channel) then
      if choice = Allowed then
        return
      else
        raise ContactNotAllowed
    else
      raise ContactNotAllowed

class SendRecall
  - preferences: PatientPreferences
  + new(preferences: PatientPreferences)
  + run(patient: PatientId, channel: ContactChannel): void
    raises ContactNotAllowed
    language := preferences.languageOf(patient)
    choice := preferences.choiceOf(patient, channel)
    if language.hasTemplateFor(channel) then
      if choice = Allowed then
        return
      else
        raise ContactNotAllowed
    else
      raise ContactNotAllowed
```

`SendReminder` and `SendRecall` each read the language and the choice
once and run the same nested check; the check appears twice, so a change
to the rule needs an edit in both. Both scripts change nothing and store
nothing, so they open no transaction; the fence leaves that out.

- The transaction script has no place for it. Each request that asks the
  question reads the language and the choice and repeats the check, so a
  change to the rule touches every copy. A third request adds a third
  copy.
- The domain model writes `mayBeContactedBy` once, and both requests ask
  the patient's contact object. A new channel with a template, or a
  change to what a choice allows, changes one method.
- The table module also writes `mayBeContactedBy` once, but every other
  operation on the table repeats the row lookup and may write a field
  directly. The rule is easy to bypass, and a caller that holds a row can
  change the data the rule reads.

## Signs a module has outgrown scripts

- One check is copied into a second request, or into a second entry point
  that reaches the same store.
- Two procedures read and write the same set of fields, so a change to
  one rule needs an edit in both.
- The rules depend on one another: the contact rule needs the language
  and the choice, and neither alone answers it.
- A request needs a value another request computes, so one procedure
  calls another.
- A change to one rule keeps touching more than one procedure.

## Moving one use case at a time

A module moving from scripts to a domain model keeps one style per use
case. Move the reminder first, and leave the recall as a script until its
turn comes.

- Put the new domain object beside the old store. Do not let an old
  script write the new object's fields.
- Change one use case wholly to the model, so no use case has two styles
  at once.
- List the scripts still to move where the team tracks the work, so the
  move does not stall with neither style complete.
- Delete a script when its use case asks the model, and keep the old
  store only for the scripts that still use it.
- Remove the old store when the last script has moved.
