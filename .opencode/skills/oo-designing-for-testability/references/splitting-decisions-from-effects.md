# Splitting decisions from effects

Some work can run only where a printer, a network or a database is
present. Keep the part that decides in an object that reads plain
values and answers plain values, so a test can check the rule without
the collaborator.

A monthly vaccination report is one example. `VaccinationReport` takes
the month's doses as a `List<Dose>` and answers `ReportFigures`:
`figuresFor(doses)` holds every rule about what the report counts. A
test builds a list of `Dose` values for one month, calls `figuresFor`,
and checks the figures. No printer, database or clock is involved, and
the test repeats because every input is a value it chose.

A second, small object hands the figures to the printer.
`VaccinationReportPrinter` holds `ReportPrinter`, whose `print` takes
`ReportFigures`. Its `printFor(report, doses)` asks the report for the
figures and passes them to the printer once. It decides nothing, so it
needs no test of its own; when a team wants to pin the wiring, one test
hands it a recording `ReportPrinter` and checks the figures it received.

The split is not worth it when there is nothing to decide. Rule 6's
exception covers a method that passes a value straight to its port: one
small class is enough, and moving its one line into another object only
adds a name to follow.

This is the same split that
[layering the system](../../oo-layering-the-system/SKILL.md) rule 4 asks
of a screen or a job at an edge, used inside one class: the part that
needs the outside world stays small and humble, and the rule moves to
an object a test can call with plain values.
