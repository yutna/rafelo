# Data at the boundary

Some data arrives as a plain shape. A clinic defines its opening hours
in settings, a tenant adds a field, and another system sends a payload.
This reference keeps those shapes as data and gives the one rule that
reads them a home.

## Opening hours a clinic defines

Each clinic sets its own hours. A class per clinic or per schedule would
need a deployment each time the hours change. Keep the hours as a list
of periods, each with a day, an opening time and a closing time, and let
one value answer the question a slot asks about them.

```text
value OpeningPeriod
  - day: Weekday
  - opensAt: TimeOfDay
  - closesAt: TimeOfDay
  + new(day: Weekday, opensAt: TimeOfDay, closesAt: TimeOfDay)

value OpeningHours
  - periods: List<OpeningPeriod>
  + new(periods: List<OpeningPeriod>)
  + covers(start: DateTime): Boolean
    return periods.anyCovers(start)
```

`anyCovers(start)` is taken to mean true when some period in the list
covers that start; the check is one message to the list.

## The one rule

The hours carry one rule: a slot starts inside them. `OpeningHours`
answers it whole in `covers`: whoever builds a slot asks `covers` first
and refuses a start outside the hours. A service that checks the slot
after the fact would split the rule from the hours it reads.

## Records for values that are only data

`OpeningPeriod` is a record: it holds a day and two times, compares by
value, and has no rule beyond its own construction. `OpeningHours` also
starts as a record; it gains one method because one rule needs it. That
is the whole difference between plain data and a domain object here.
