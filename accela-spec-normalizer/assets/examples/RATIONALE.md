# Why these examples are shaped this way

Syntax is easy to copy. The shaping decisions are what matter, and each of these was
arrived at by first producing something unreadable.

## workflow-state-graph.mmd

Four separate cubic-yard results in the source collapse into two edges, distinguished
only by their scheduling offset. Drawn faithfully — one edge per result value — the
graph had four parallel edges between the same pair of states and the labels stacked on
top of each other. The information is not lost; it lives in Table B, which is where
someone looking up a specific status will actually go.

`Appealed` and `Assessed` are drawn with no outbound transition. That is deliberate.
The source spec lists them as payment statuses and never says what follows. Drawing
them as dead ends makes the omission visible instead of quietly tidying it away, and it
is the diagram's job to show the spec as written.

## inspection-lifecycle.mmd

Nine result values become three routing classes: close, reinspect, spawn child. The
individual values are edge labels only where they fit; the full list is Table A. This
is the same instinct as the state graph — a diagram that tries to be the table stops
being readable as a diagram and does not replace the table anyway.

The reinspection appears as a second inspection node rather than a loop back to the
first. They are different inspection types with different result sets, so a loop would
be wrong on the facts as well as harder to read.

## event-chain.mmd

Two columns, hooks on the left and effects on the right, rather than a chain. Accela
event scripts do not compose into a sequence — they are independent hooks that happen
to act on the same record. A left-to-right pairing says that honestly; a linear flow
would imply an ordering that does not exist.

The nightly batch gets the terminal class specifically so it does not look like an
event. That distinction is the single most useful thing this diagram conveys: the
37-day late fee is not triggered by anything a user does, and anyone who assumes it is
will go looking for a hook that cannot exist.

## What is not here

There is no diagram for the record type header card. It is reference data — a list of
configured names and values. Rendering it as a graph makes it uneditable and conveys
nothing that a two-column table does not.
