# Wrapping an outside API

A provider outside the clinic publishes its own client, its own record
type and its own error codes. The clinic needs one lookup from it. This
reference puts that lookup behind a port declared beside the domain and
keeps the provider behind one adapter.

## The port and its adapter

`RegionalRegister` is the clinic's port for looking up a patient on a
regional register, and `RegisteredDetails` is the value the clinic
reads from it. `HealthNumber` is the clinic's value for a patient's
health number, used here as a type.

```text
interface RegionalRegister
  + detailsFor(number: HealthNumber): RegisteredDetails?
    raises RegisterRecordIncomplete, RegisterUnavailable

value RegisteredDetails
  - surname: String
  - bornOn: Date
  + new(surname: String, bornOn: Date)

class RegisterAdapter implements RegionalRegister
  - client: RegisterClient
  + new(client: RegisterClient)
  + detailsFor(number: HealthNumber): RegisteredDetails?
    raises RegisterRecordIncomplete
    record := client.lookup(number.text())
    if record = null then
      return null
    else
      if record.familyName() = null then
        raise RegisterRecordIncomplete
      else
        if record.dateOfBirth() = null then
          raise RegisterRecordIncomplete
        else
          return new RegisteredDetails(record.familyName(),
            record.dateOfBirth())
```

`RegisterClient` is taken to be the provider's own client, whose
`lookup` answers the provider's own record type, whose `familyName()`
and `dateOfBirth()` answer the fields the clinic reads; the client and
the record are the provider's types, used only in this adapter.
`number.text()` is taken to write the health number in the form the
provider expects. The fence stores nothing. The adapter turns the
provider's failures into `RegisterUnavailable`, and this fence leaves
that translation out because the notation has no way to catch an error.

## Turning the provider's errors into clinic errors

When `lookup` fails, the provider answers with its own error codes and
its own error types. The adapter turns each code it understands into a
clinic error in its place, so no caller outside the adapter names a
provider code. A code the adapter does not recognise becomes
`RegisterUnavailable`, the clinic's own error, so an unexpected answer
still arrives in the clinic's terms. The port declares only clinic
errors, and every failure a caller can see is one it can handle.

## Testing the adapter against the provider's examples

The provider documents its lookup with example requests and replies,
including replies with a missing field. The adapter's tests run those
examples as they are: a complete example becomes `RegisteredDetails`, a
reply with no record becomes `null`, and each incomplete example raises
`RegisterRecordIncomplete`. The tests also cover every provider error
code the adapter translates. When the provider publishes a new example,
the test file gains a case and the rest of the clinic does not change.

## When the provider releases a new version

When the provider changes its API, the adapter is the only class that
must change: its client call, its record type and its error
translation. The port keeps the clinic's terms, so the domain and its
tests do not move. A new provider version can arrive as a second
adapter behind the same port, chosen at the composition root, while the
old one serves until the clinic has moved.
