# Vague words

A word that could name any class names no class. It hides a job, so a
reader has to open the file to learn what the class does. Ask the
question in the middle column; the answer points to the kind of name in
the last column.

|Word|Question it should prompt|Kind of name that answers|
|---|---|---|
|Manager|Which one job does it coordinate?|The job, such as `BookingDesk`|
|Helper|Which object should hold it?|The owner, such as `WaitingList`|
|Util|Which concept do these methods serve?|The concept, such as `Fee`|
|Processor|What does one run of it produce?|The result, such as `InvoiceRun`|
|Handler|Which event does it answer?|The action, such as `CheckIn`|
|Data|What may callers do with the values?|The role, such as `PatientRecord`|
|Info|Which question does it answer?|The answer, such as `SlotSummary`|

## What each word hides

`Manager` hides the activity the class coordinates. If it really does
coordinate a flow, name the flow: `BookingRun` says when the class starts
and what it finishes. A `Helper` or a `Util` usually holds a method that
belongs on the object whose data it reads; naming that object names the
class. A `Processor` hides its output, and a `Handler` hides the event it
answers. `Data` and `Info` hide the role a value plays, so name the role
the caller sees.

## Pattern names that carry meaning

`Factory` and `Repository` name a mechanism rather than a clinic
concept, so the default in core rule 3 would replace them. They stay
when callers must know the mechanism: a repository says the object may
come from storage, and a factory says the object is built from parts the
caller does not choose. The name is then the class's meaning to its
callers, not a leak from inside it. When the mechanism is private, use
the domain name instead: `AppointmentBook` while storage stays hidden,
`AppointmentRepository` once callers must know they are asking a store.
