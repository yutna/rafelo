# Secrets and depth

A module earns its boundary by keeping a decision that is likely to
change. Splitting work by the order of its steps gives every class the
same decision to know. Depth is the same idea seen from the caller's
side: a small interface over work that stays inside.

## A decision, not a step

A clinic exports each visit to a file that another system reads. In a
design split by steps, `ExportWriter` and `ExportReader` each keep the
file's column list, so the column order and each column's meaning are
known twice. A new column changes both classes, and either can drift
from the other without a test noticing until a file is read back.

```text
class ExportWriter
  - columns: List<ColumnName>
  + new(columns: List<ColumnName>)
  + lineFor(visit: Visit): String

class ExportReader
  - columns: List<ColumnName>
  + new(columns: List<ColumnName>)
  + visitIn(line: String): Visit
```

`ColumnName` is taken to be a column name in the export file's own
terms. Each constructor sets its `columns` field from the list it
receives. The two lists agree only because someone keeps them in step.
`Visit` is the clinic's visit as the pack already models it; the
export carries one without changing the visit's shape.

The same work has one secret when the format lives in one module. The
writer asks for the line and appends it to its destination. The reader
answers the visit at the line its source is on, asking the format what
visit the line holds; a separate command moves the source past that
line. Neither knows the columns.

```text
class VisitFile
  + lineFor(visit: Visit): String
  + visitIn(line: String): Visit

class ExportWriter
  - file: VisitFile
  - destination: ExportDestination
  + new(file: VisitFile, destination: ExportDestination)
  + write(visit: Visit): void
    destination.append(file.lineFor(visit))
    return

class ExportReader
  - file: VisitFile
  - source: ExportSource
  + new(file: VisitFile, source: ExportSource)
  + currentVisit(): Visit
    visit := file.visitIn(source.currentLine())
    return visit
  + advance(): void
    source.advance()
    return
```

`VisitFile.lineFor` is taken to lay out one visit in the file's field
order and answer the line, and `VisitFile.visitIn` is taken to read one
such line back into a visit. `ExportDestination.append(line)` is taken
to append one line to the destination. `ExportSource.currentLine()` is
taken to answer the line the source is at and change nothing, while
`ExportSource.advance()` moves it past that line.
`ExportReader.currentVisit()` answers the visit at the line its source
is on and changes nothing; `ExportReader.advance()` moves the source
past that line and answers nothing. Each constructor sets its fields
before its method reads them. A new column changes `VisitFile` alone.
The format is the secret; the writer owns the destination, the reader
owns the source, and the format stays in `VisitFile`.

## Deep or shallow

The Pattern's before `DayPlan` is shallow: three public messages about
blocks, and a caller must handle a day's blocks by index. After,
`DayPlan` is deep: `reserve` and `isFree` are two messages over the same
list, and the block layout and its index stay inside. The shallow class
asks callers to know as much as its code does; the deep class asks only
what a caller may want to do.

A class is not deep just because it is small. A wrapper that repeats an
outside library one method for one method has the outside interface plus
a shell, so a caller still knows every outside step. Depth comes from
hiding a decision, not from renaming each call.

## Splitting by steps

A process split into a class per step gives each class the same shared
format, limit or protocol to know, because every step touches the same
record. The format then has as many owners as there are steps, and a
change to it visits every one. Draw the line around the decision
instead: one class owns the format and offers the outcome, and the steps
either move inside it or send it messages. The steps still exist inside
the class; they are no longer the module boundary.
