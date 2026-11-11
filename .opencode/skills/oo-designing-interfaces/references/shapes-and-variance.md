# Shapes and variance

- [Two ways to match a type](#two-ways-to-match-a-type)
- [Why a named role still helps](#why-a-named-role-still-helps)
- [Handing values out](#handing-values-out)
- [Taking values in](#taking-values-in)
- [Both at once](#both-at-once)

A type can be matched by the name it declares or by the messages it
answers. This reference describes both in prose, says why a named role
helps even when the match is by shape, and gives the direction a
generic parameter may take. The language packs show the syntax for
stating either match. `Vaccination`, `VisitKind` and `Procedure` are
used only as types and keep the shapes the polymorphism skill gives
them.

## Two ways to match a type

Where a language matches by name, an implementation must declare the
interface's name. The declaration is checked, and a reader sees at once
which types play which role. Where a language matches by shape, any
type that answers the messages fits, with no declaration. That is
convenient for a small role, but the reader cannot tell from the type
alone which matches were intended.

Neither way is better for every case. A named role gives the reader a
word for the caller's need; a shape gives a short contract without a
declaration. The rest of this reference uses the named role and says
where a shape is enough.

## Why a named role still helps

Two unrelated types whose messages happen to share names become
interchangeable by accident. A named role says that the match is meant,
and a reader can tell a real implementation from one that merely looks
alike. Where shape decides, the name is documentation and a target for
a test stand-in; it does not change the check the language makes.

## Handing values out

A type that only hands values out may be read as one of a wider type.
Every vaccination is a visit kind, so a `ReadOnlyList<Vaccination>` can
be read where a `ReadOnlyList<VisitKind>` is expected. A caller can read
each vaccination as a visit kind, and no caller can add a procedure
through that view.

```text
class VaccinationList
  - vaccinations: List<Vaccination>
  + new()
    vaccinations := new List<Vaccination>()
  + readOnly(): ReadOnlyList<Vaccination>
    return vaccinations.readOnlyView()
  + asKinds(): ReadOnlyList<VisitKind>
    return vaccinations.readOnlyView()
```

`asKinds` returns the read-only view as a `ReadOnlyList<VisitKind>`.
`readOnlyView()` is the notation's own operation; it returns a
`ReadOnlyList` that shows the list without changing it.
`new List<Vaccination>()` is taken to make an empty list, and the
constructor sets `vaccinations` before either method reads it.

## Taking values in

A type that only takes values in may stand in for one that takes a
narrower type. A recorder that accepts any `VisitKind` can stand where
a caller needs a recorder of `Vaccination`, because every vaccination
is a visit kind. The reverse is not safe: a recorder of `Vaccination`
cannot be handed a procedure and asked to record it.

```text
interface VisitRecorder
  + record(visit: VisitKind): void

class VaccinationRun
  - recorder: VisitRecorder
  + new(recorder: VisitRecorder)
  + record(vaccination: Vaccination): void
    recorder.record(vaccination)
    return
```

`VaccinationRun` sends its vaccination to a `VisitRecorder`, which
accepts every visit kind. The role takes values in and hands nothing
back, so the wider parameter is safe. The constructor sets `recorder`
before `record` reads it, and one record call sends one message.

## Both at once

A type that both takes values in and hands them out stays exact. `List`
is that case: its `add` takes a value in and its reads hand values out.
A `List<Vaccination>` cannot stand where a `List<VisitKind>` is added
to, because a `Procedure` could be added through the wider view and a
reader of the original list would then meet a procedure where it
expects a vaccination. A `ReadOnlyList` avoids that, because it only
hands values out.
