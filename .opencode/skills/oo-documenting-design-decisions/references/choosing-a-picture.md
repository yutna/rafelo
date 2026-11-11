# Choosing a Picture

A picture earns its place when it shows what the code cannot show
quickly, as rule 4 says. It keeps to one level, as rule 5 says, and
stays a dated sketch, as rule 6 says. This file lists the levels and
walks through one choice.

## Four levels

- **The system among its neighbours.** The clinic system, the people
  who use it, such as receptionists, clinicians and patients, and the
  other systems it exchanges data with. It answers who depends on the
  system and what crosses its edge.
- **The deployed parts.** Each part that is deployed and run on its
  own, such as the web application, the database and the file store,
  and how they talk. It answers what runs where.
- **The modules of one part.** The business modules inside one
  deployed part, such as scheduling, billing and clinical records, and
  which depends on which. It answers where a change will land.
- **The classes of one knot.** A handful of classes that are hard to
  follow in the code, and the messages between them. It answers how one
  small piece works, and is often thrown away after the conversation it
  served.

## When to draw

- Draw who talks to whom across module or system boundaries: the code
  spreads that over many files.
- Draw one flow that passes through several objects, as a numbered list
  of steps.
- Draw the states of a lifecycle and the transitions that leave each.
- Do not draw what one file or one folder already shows, such as the
  classes of a small module or the fields of one class.

## A worked choice

A new developer must change how clinical photographs reach the file
store, and asks for a picture. Two pictures are possible.

1. A picture of every class in the photographs module. Its file list
   already shows them, so this picture is not drawn.
2. A picture of the deployed parts a photograph passes through: the web
   application, the database that keeps the visit's row and the
   photograph's identifier, and the file store that keeps the
   photograph. The code spreads this over an adapter, a use case and
   the store's settings, so this picture is drawn, at that one level.

The picture is dated, kept beside decision record 12 in the repository,
and named in the record. When the photographs move to a new archive,
the change that moves them redraws the picture, so the picture ends
showing only stores the code uses, as rule 6 asks.
