# When the Framework Is Not Object-Oriented

Some frameworks build a screen from functions and components that hold
no domain objects, and pass plain data and functions between them. Rule
5 keeps the clinic's rules out of the components, in a module of their
own written in the code base's idiom. This file says where the domain
lives in such code, then walks through one screen.

## Where the domain lives

- The components show data and pass the user's actions on. Screen
  logic, such as which button is enabled, sits in what holds the
  screen's state, where a test drives it without drawing the screen, as
  separating presentation from domain, rule 2, asks. No clinic rule sits
  in either.
- The clinic's rules live in a module of their own that the components
  call. It imports nothing from the framework, so a test calls it
  without drawing a screen.
- That module follows the idiom of the code around it, as patterns the
  language provides, rule 7, asks: where the code base is built of
  functions and plain values, the module is too, and its rules are
  functions over values; where the team builds classes, the module may
  hold classes. Classes forced into code built of functions add a
  second idiom every reader must switch between.
- Calls that leave the program, such as fetching a patient's
  appointments, sit at the edge of the module, so the rules inside it
  answer from values alone.

## A worked screen

A screen lets a patient pick a slot for a follow-up visit, in a code
base built of functions and plain values.

1. What holds the screen's state keeps which slot the patient has
   chosen and whether the confirm button is enabled: screen logic, which
   a test drives without drawing the screen.
2. When the patient confirms, the component calls a function of the
   booking module with the chosen slot and the patient's identity.
3. The booking module decides, from the values it is given, whether
   this patient may take this slot, and answers the booking, or refuses
   it with an error named in the clinic's words, such as `SlotTaken`.
   It uses no framework type.
4. The component shows the answer.

The screen ends with the rule about who may take a slot in the booking
module, where a test calls it with plain values, and with no clinic
rule in the component or in what holds the screen's state, as rule 5
asks.
