# A Pure Core in a Shell

Rule 3 arranges a use case so that the reading and the writing happen
around the decision, never inside it. This file shows the arrangement,
then walks through one use case.

## The arrangement

1. The shell reads everything the decision needs: the aggregates,
   through their repositories, and any fact from outside, through its
   port.
2. The core decides from those values and domain objects alone, and
   answers what should happen. It reaches no port.
3. The shell carries out what the answer names: it stores what
   changed, in the transaction the use case opens and ends, as placing
   domain logic, rule 2, gives that work to the application service.

A test of the core builds values and domain objects, sends one message,
and checks the answer, with no stand-in at all.

## A worked use case

Each week the clinic asks a nurse to call every patient whose home
weight readings have fallen too fast since the last visit.

1. The shell reads, through the readings' repository, each patient's
   readings for the week and the reading taken at the last visit, and
   loads the week's call list.
2. The core works out, for each patient, whether the week's readings
   have fallen further than the clinic allows since the last visit, and
   answers the patients a nurse should call. It reads no store and
   sends nothing.
3. The shell adds those patients to the call list and stores the call
   list, one aggregate, in the transaction the use case opens and ends.

A test of step 2 passes readings as values and checks the patients it
answers, with no repository, no call list and no stand-in. The use case
ends with every decision in the core and every read and write in the
shell, as rule 3 asks.
