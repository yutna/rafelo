# Equality and identity

A value and an entity answer "is this the same thing?" in different
ways: a value answers with its contents, an entity with its identifier.
Anything built on the answer, such as a hash or an ordering, follows the
same rule, or a lookup silently misses.

## A value compares by its contents

In the notation `value` gives equality by every field, and that is the
whole comparison. Two `RoomLabel` values with the same number are the
same value, even when the text that built them arrived in different
letters. A third label with a different number is a different value.
Nothing in a value ever changes, so its equality cannot go stale.

## An entity compares by its identifier

An entity changes while it lives, so its other attributes cannot say
which thing it is. The identifier can.

```text
class Clinician
  - clinicianId: ClinicianId
  - surname: String
  + new(clinicianId: ClinicianId, surname: String)
  + clinicianId(): ClinicianId
    return clinicianId
  + surname(): String
    return surname
  + rename(newSurname: String): void
    surname := newSurname
    return
  + sameAs(other: Clinician): Boolean
    return clinicianId = other.clinicianId()
```

Two copies of one stored clinician are the same clinician even when one
copy holds an older surname. `sameAs` compares `clinicianId` with
`other.clinicianId()`, and `=` on two `ClinicianId` values compares their
contents. The surname stays out of the answer, because `rename` changes
it during the clinician's life; a comparison by surname would answer
differently before and after one rename. Comparing the two `Clinician`
objects with `=` would also answer false, because they are two object
instances.

## Equality, hashing and ordering agree

A hash and an ordering are two more answers to "is this the same
thing?", so both must follow the same contents as equality. Two equal
values must hash alike, and an ordering must rank two values as equal
exactly when they are equal. A map or a set looks up a key by its hash,
so an equal value with another hash sits where the lookup never looks.
A sorted set or a sorted map decides sameness by the ordering alone:
rank 10 in one currency against 10 in another as equal and it drops
one of them, and rank two equal values as different and it keeps both.
When equality is written by hand, write hashing and ordering against
the same fields, all of them.

## One room, two jobs

The same concept can play both parts in one clinic, and then the part
decides.

```text
value RoomLabel
  - number: String
  + new(number: String)

class Room
  - roomId: RoomId
  - label: RoomLabel
  + new(roomId: RoomId, label: RoomLabel)
  + roomId(): RoomId
    return roomId
  + relabel(newLabel: RoomLabel): void
    label := newLabel
    return
```

On an appointment letter, the room is a `RoomLabel`: a letter that says
4B and another that says 4B name the same room, and nobody tracks the
letter after it is sent. For the facilities team, the room is a `Room`
entity: it has a `RoomId` that survives a relabel, because equipment and
repairs are tracked against the room, not against the sign on the door.
Decide by what that part of the system tracks, not by the word.
