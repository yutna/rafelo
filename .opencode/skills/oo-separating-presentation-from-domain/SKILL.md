---
name: oo-separating-presentation-from-domain
description: Use when choosing MVC, MVP or MVVM for a screen, when a screen binds straight to domain objects, or when a background task updates a screen.
license: MIT
metadata:
  version: 0.17.1
  pack: object-oriented-design-skills
---

# Separating Presentation from Domain

**In this pack:**
[sizing](../oo-design/SKILL.md#how-much-design-a-task-warrants),
[notation](../oo-design/references/notation.md),
[rule strictness](../oo-design/SKILL.md#how-strictly-a-rule-is-meant).

## Overview

A screen shows what the user sees and passes on what the user asks for.
The rules that decide whether an action may happen belong to the domain,
behind a use case, and the screen's own state and logic belong to a
presentation object that a test can drive without the toolkit. This
skill keeps the business out of the view, chooses how much the view
knows, lets changes reach the domain one way, holds the screen's state
as values shaped for the screen, and touches the screen only on its
user-interface thread.

## When to use

- You are choosing model-view-controller, model-view-presenter or
  model-view-viewmodel for a screen.
- A screen, form or event handler binds straight to a domain object.
- A background task updates a screen, or a slow call freezes it.
- Screen logic, such as which buttons are enabled, can only be reached
  by a test that runs the toolkit.
- A view and a domain object each update the other.

## When not to use

- The question is which layer a screen's code depends on, or how a
  scheduled job or a message listener is kept humble: that is
  [layering the system](../oo-layering-the-system/SKILL.md).
- The question is which domain object or use case decides a business
  rule: that is
  [placing domain logic](../oo-placing-domain-logic/SKILL.md).
- The screen decides nothing, such as a page of fixed text.
- The module's user interface is already written in a functional style,
  such as components that are functions of their state. Follow that
  idiom, and keep only the rule that the business stays out of the view.

## Core rules

1. Rule. **Keep the business out of the view.** A screen shows state and
   passes on what the user asked for, and the rules that decide whether
   it may happen stay in the domain, behind a use case, as
   [assigning responsibilities](../oo-assigning-responsibilities/SKILL.md)
   rule 5 asks. A view that checks whether a patient may book holds a
   second copy of a rule the domain already keeps.

2. Default. **Put a screen's state and its screen logic, such as which
   buttons are enabled and which message shows, in a presentation object
   that holds what the screen shows and that a test can drive without
   the screen.** The object is a presenter that tells the view what to
   show, or a presentation model, called a view model where the view
   binds to it.

   The exception is a screen that only shows a value and decides
   nothing, such as a clock in a corner.

3. Judgement. **Choose how much the view knows.** A passive view leaves
   every widget to the presenter, so a test can reach all its logic. A
   supervising controller lets the view bind plain fields on its own and
   hands the rest to the presenter. A view model needs a toolkit that
   keeps the view in step with it. What tips the balance is how well the
   toolkit binds and how much of the screen's logic a test must reach
   without it.

4. Rule. **Let changes reach the domain one way.** The view hands the
   user's intent to the presentation object; that object asks a use case
   and updates its own state, and the view redraws from it. A binding
   between the view and its presentation object may run in both
   directions. What no binding may do is reach a domain object.

5. Rule. **Hold a screen's state as values shaped for the screen, never
   as the domain object itself.** A screen bound to the object that
   holds a patient's contact details lets the toolkit set its fields as
   the user types, past its rules, and leaves half-typed values in an
   object the store may save. That is not the change
   [encapsulating state and
   behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md) rule 2
   allows: state changes through a method named for the domain action.
   That rule's exception lets a framework map fields at the edge when it
   loads and stores an object. A screen's binding is not that case,
   because it writes what the user types before any rule has checked
   it.

6. Rule. **Touch the screen only on the toolkit's user-interface
   thread.** Run a slow use case off that thread, and hand its result
   back to that thread to update the presentation object's state. A
   screen written from a thread that does not own it fails
   unpredictably, and one held up by a slow call freezes.

## Pattern

Before, `BookingScreen` holds the screen's state and decides whether
its button is enabled. The rule for when booking may be asked for lives
in `BookingScreen`, so only a test running the toolkit can reach it.

Before:

```text
class BookingScreen extends FrameworkScreen
  - bookButton: FrameworkButton
  - chosenSlot: SlotId?
  - chosenPatient: PatientId?
  + new(bookButton: FrameworkButton)
    chosenSlot := null
    chosenPatient := null
  + onSlotChosen(slot: SlotId): void
    chosenSlot := slot
    if chosenPatient = null then
      bookButton.disable()
    else
      bookButton.enable()
  + onPatientChosen(patient: PatientId): void
    chosenPatient := patient
    if chosenSlot = null then
      bookButton.disable()
    else
      bookButton.enable()
```

`bookButton.disable()` and `bookButton.enable()` are taken to disable
and enable the toolkit's button once each. The constructor sets
`bookButton`, `chosenSlot` and `chosenPatient` before the handlers read
one, and each handler sets one choice once and sends `disable` or
`enable` once. The fence changes and stores nothing in the domain.

After, `BookingPresenter` holds the choices and the rule, and tells a
`BookingView` what to show. A test builds the presenter with a stand-in
view and drives the decision without the toolkit.

After:

```text
interface BookingView
  + showBookEnabled(enabled: Boolean): void

class BookingPresenter
  - view: BookingView
  - chosenSlot: SlotId?
  - chosenPatient: PatientId?
  + new(view: BookingView)
    chosenSlot := null
    chosenPatient := null
  + slotChosen(slot: SlotId): void
    chosenSlot := slot
    showBookable()
    return
  + patientChosen(patient: PatientId): void
    chosenPatient := patient
    showBookable()
    return
  - showBookable(): void
    if chosenSlot = null then
      view.showBookEnabled(false)
    else
      if chosenPatient = null then
        view.showBookEnabled(false)
      else
        view.showBookEnabled(true)
    return
```

`FrameworkScreen` and `FrameworkButton` stand for any toolkit's own
types, and the skill names none. `true` and `false` are the two values
of `Boolean`. `SlotId` and `PatientId` are values used as types. The
screen implements `BookingView`, passes each choice the user makes to
the presenter, sets its button from `showBookEnabled`, and holds no
logic. It is wired at the composition root, which this fence leaves
out. The fence changes and stores nothing in the domain.
`BookingPresenter`'s constructor sets `view`, `chosenSlot` and
`chosenPatient` before any method reads one, and each choice sends
`showBookEnabled` once: `showBookable` takes the nested `if` and sends
it on one branch only.

## Red flags

Places to look, not verdicts. A red flag becomes a finding only with
evidence: a measurement, a reproducible bug, or a failing test.

- A screen's event handler that decides a business rule.
- A form whose fields are bound straight to a domain object.
- Screen logic, such as which buttons are enabled, that a test can reach
  only by running the toolkit.
- A view and a domain object that update each other.
- A slow call made on the user-interface thread.
- A widget written from a background thread.

## Common mistakes

- Moving a screen's logic into a domain object so that a test can reach
  it.
- Giving a presenter to a screen that decides nothing.
- Letting the presentation object reach the store itself rather than
  through a use case.
- Copying a pattern into a module whose user interface already uses
  another.
- Letting a late result from a background task overwrite the newer state
  on screen.

## Related skills

- [oo-design](../oo-design/SKILL.md) sizes a task and defines the rule
  labels.
- [oo-layering-the-system](../oo-layering-the-system/SKILL.md) keeps a
  screen with its framework humble and leaves presentation patterns
  outside its rules.
- [oo-assigning-responsibilities](../oo-assigning-responsibilities/SKILL.md)
  sends a request from a user interface first to a use-case object.
- [oo-placing-domain-logic](../oo-placing-domain-logic/SKILL.md) decides
  in the domain whether a request is allowed.
- [oo-encapsulating-state-and-behaviour](../oo-encapsulating-state-and-behaviour/SKILL.md)
  changes state through a method named for the domain action.

## Further reading

- [Presentation patterns](references/presentation-patterns.md)
- [One-way flow and threads](references/one-way-flow-and-threads.md)
