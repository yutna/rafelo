# Presentation patterns

Every pattern below splits one screen into parts so that the business
stays out of the view and the screen's own logic can be tested. The
names are common vocabulary; this reference gives each one the job this
pack's words give it.

## Model-view-controller

The first form of model-view-controller puts three parts around one
model. The model holds the state and tells the views that show it when
that state changes. A view draws what the model holds and asks it for
what it needs. A controller turns each input into a message on the
model: the user pressed a button, so the controller asks the model to do
something, and the model tells its views to redraw.

Web frameworks use the same name for a narrower split. One controller
runs per request: it reads the request, asks the model, and chooses the
view that renders the reply. The model keeps no list of views and the
views do not watch it. The request ends the controller's life, so the
screen's state lives in the request and in the store rather than in a
long-lived object.

That first description is the name's origin, not the loop this skill
asks for. Rule 4 keeps the flow one way: the view sends intent through a
presentation object and redraws from that object's state, and no binding
joins the view to a domain object. A module that calls its screens
model-view-controller today keeps the model behind a use case and lets a
presentation object hold the screen's state and pass the intent on; its
controller is part of that presentation object.

## Model-view-presenter

Model-view-presenter puts a presenter between the view and the model.
The view reports each user action to the presenter. The presenter holds
the screen's state, asks a use case, and tells the view what to show.
Two versions differ in how much the view does.

A passive view sets no widget itself and holds no decision. The
presenter sets every widget through messages the view declares, so a
test hands the presenter a stand-in view, checks the messages it
receives, and needs no toolkit. The cost is one message per widget.

A supervising controller lets the view bind plain fields itself, for
values a toolkit can show without a decision, and leaves the decisions
and the remaining widgets to the presenter. It is less writing than a
passive view, and the binding it leaves in the view is the part a test
without the toolkit cannot reach.

## Presentation model and view model

A presentation model holds the state and the logic of one screen in an
object shaped for that screen, not for the domain. The view asks it what
to show. A view model is a presentation model that a toolkit binds to:
the toolkit writes what the user types into the view model and redraws
the widgets when the view model changes. The binding belongs to the
toolkit, so the view holds almost nothing, and a test drives the view
model without the toolkit.

## Comparing them

|Pattern|State held by|Widgets set by|A test drives|
|---|---|---|---|
|Model-view-controller|the model|the view|the model and controller|
|Web model-view-controller|the request and store|the view|controller and model|
|Presenter, passive view|the presenter|the presenter|the presenter|
|Presenter, supervising|the presenter|the view and presenter|the presenter|
|Presentation model|the presentation model|the view|the presentation model|
|View model|the view model|the toolkit binding|the view model|

Read the table one column at a time. The second says what a test builds
to hold the screen's state. The third says who writes the widgets, and
whatever the view or the toolkit binding writes is what a test without
the toolkit cannot reach. The last says what the test can still check.

## Telling which one a codebase uses

Look at the view first. A view with a setter for every widget is a
passive view. A view that binds its own plain fields is a supervising
controller. A view that binds an object named for the screen has a view
model, which is a presentation model.

Then look at the model. A model that keeps a list of views and tells
them when it changes is the first form of model-view-controller. A
handler that reads one request, asks the model and returns a rendered
reply is the web form.

Then follow the calls. An object that receives each user action and
tells the view what to show is a presenter. An object the view reads for
every value it shows is a presentation model.

A module keeps the pattern its screens already follow. The pattern is
the boundary every screen and every screen test shares, so replacing it
rewrites both at once. A new screen follows the module's pattern, and a
pattern changes only when the one in use blocks a rule of this skill,
such as testing the screen logic without the toolkit.
