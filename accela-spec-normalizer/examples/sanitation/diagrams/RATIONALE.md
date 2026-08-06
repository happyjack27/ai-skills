# Why these examples are shaped this way

Syntax is easy to copy. The shaping decisions are what matter, and each of these was
arrived at by first producing something unreadable.

These live as `.md` files with a fenced ```mermaid block, not bare `.mmd`. No installed
VS Code extension registers a custom editor for `.mmd` (they only offer a preview
*command*), so a bare `.mmd` file has no default rendered view here. Wrapping the same
source in Markdown renders automatically, since Markdown Preview is already the default
editor for `.md` and `bierner.markdown-mermaid` renders the fenced block. Real
deliverables to Accela configurers (Stage 5) are unaffected by this — those ship as
`.mmd` + a generated `.svg`, viewed by whoever receives the export, not by an agent
working in this repo.

## workflow-state-graph.md

Four separate cubic-yard results in the source collapse into two edges, distinguished
only by their scheduling offset. Drawn faithfully — one edge per result value — the
graph had four parallel edges between the same pair of states and the labels stacked on
top of each other. The information is not lost; it lives in Table B, which is where
someone looking up a specific status will actually go.

`Appeal` and `Assessment` — the tasks that `Appealed`/`Assessed` hand off to — are drawn
with no outbound transition. That is deliberate. The hand-off itself is stated in
Table B, so it is not a gap; what neither task resolves to afterward is. Drawing them
as dead ends makes that omission visible instead of quietly tidying it away, and it is
the diagram's job to show the spec as written.

## inspection-lifecycle.md

Nine result values become three routing classes: close, reinspect, spawn child. The
individual values are edge labels only where they fit; the full list is Table A. This
is the same instinct as the state graph — a diagram that tries to be the table stops
being readable as a diagram and does not replace the table anyway.

The reinspection appears as a second inspection node rather than a loop back to the
first. They are different inspection types with different result sets, so a loop would
be wrong on the facts as well as harder to read.

## event-chain.md

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
