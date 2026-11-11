# Extracting a class

A class that knows and does too much is not fixed by renaming it. Find
the parts that change together, move them to a class with a clinic name,
and leave the original as a collaborator.

## Symptoms

- The name needs "and" to describe the work: `ClinicManager` books,
  reminds and invoices.
- Its methods use separate groups of fields.
- A method reads two or more values from another object and then decides
  with them.
- Its version history changes for unrelated reasons.
- Its constructor takes many unrelated collaborators.

## Before

```text
class ClinicManager
  - appointments: List<Appointment>
  - reminders: ReminderLog
  - invoices: InvoiceBook
  + book(slot: Slot, patient: PatientId): Appointment
  + remind(appointment: Appointment): void
  + invoice(appointment: Appointment): Invoice
```

The three method groups share almost no fields. Booking changes when slot
rules change, reminders when message delivery changes, and invoices when
billing changes. That is three reasons to change in one class.

## Step by step

1. Name the reasons. Write one line for each kind of change request.
   Here they are booking rules, reminder delivery and invoice content.
2. Group the fields and methods. Put each field and method under the
   reason it serves. A field used by one group belongs with that group.
3. Move one group. Start with invoices. Create `InvoiceWriter` with the
   invoice book and one public method. Move the invoice method and its
   field, then leave a delegating call in `ClinicManager`.
4. Delete the moved code. Remove the old invoice field and the old
   invoice body from `ClinicManager`. The manager now delegates; it does
   not format invoices.
5. Repeat for reminders, then move the appointment list and booking
   method into a `ClinicSchedule`. Stop when each class has one reason to
   change and one or two roles.
6. Recheck. Run a card for each class and check coupling. `ClinicManager`
   must not reach through `InvoiceWriter` to its data.

The invoice extraction looks like this:

```text
class InvoiceWriter
  - invoices: InvoiceBook
  + new(invoices: InvoiceBook)
  + invoice(appointment: Appointment): Invoice

class ClinicManager
  - invoices: InvoiceWriter
  + new(invoices: InvoiceWriter)
  + invoice(appointment: Appointment): Invoice
    return invoices.invoice(appointment)
```

The sketch shows only the moved part; booking and reminder fields stay
for the next steps.

## After

`ClinicManager` now only forwards every call, so delete it and let
the use-case object talk to the three classes. A forwarding shell
with no rule is not a class.

```text
class ClinicSchedule
  - appointments: List<Appointment>
  + new(appointments: List<Appointment>)
  + book(slot: Slot, patient: PatientId): Appointment

class ReminderWriter
  - reminders: ReminderLog
  + new(reminders: ReminderLog)
  + remind(appointment: Appointment): void

class InvoiceWriter
  - invoices: InvoiceBook
  + new(invoices: InvoiceBook)
  + invoice(appointment: Appointment): Invoice
```

## Check the result

- Each class has one or two roles and one reason to change.
- No class holds booking, reminder and invoice data together.
- A use case delegates to a domain object instead of deciding for it.
- A new rule goes to the object that holds its data, and no caller
  reaches through one object to another.
