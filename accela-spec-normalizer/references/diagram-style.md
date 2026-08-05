# Diagram style

Copy these values literally. The point is that every record type in the estate renders
identically, so a reviewer comparing two specs sees content differences and not styling
noise, and so regenerated diagrams produce quiet diffs in source control.

## Mermaid init block

Mermaid's default `base` theme picks a node fill and a label colour that are close in
tone — readable in isolation, not readable at a glance. Set these explicitly.

```javascript
const dark = matchMedia('(prefers-color-scheme: dark)').matches;
mermaid.initialize({
  startOnLoad: false,
  theme: 'base',
  fontFamily: 'sans-serif',
  themeVariables: {
    darkMode: dark,
    fontSize: '14px',
    primaryColor:       dark ? '#0C447C' : '#E6F1FB',
    primaryBorderColor: dark ? '#85B7EB' : '#185FA5',
    primaryTextColor:   dark ? '#B5D4F4' : '#0C447C',
    lineColor:          dark ? '#9c9a92' : '#73726c',
    textColor:          dark ? '#c2c0b6' : '#3d3d3a',
    edgeLabelBackground: dark ? '#26251f' : '#ffffff',
  },
});
```

`fontSize` drives layout measurement, not just appearance. Raising text size in CSS
alone leaves the boxes sized for the old value and the labels clip. Change it here.

## Palette

Three roles only. More colours make the diagram look busier without encoding more.

| Role | Light fill | Light stroke | Light text | Dark fill | Dark stroke | Dark text |
|---|---|---|---|---|---|---|
| Default / inspection | `#E6F1FB` | `#185FA5` | `#0C447C` | `#0C447C` | `#85B7EB` | `#B5D4F4` |
| Effect / continues | `#E1F5EE` | `#0F6E56` | `#085041` | `#085041` | `#5DCAA5` | `#9FE1CB` |
| Terminal / batch | `#F1EFE8` | `#5F5E5A` | `#2C2C2A` | `#2C2C2A` | `#B4B2A9` | `#D3D1C7` |

For `.mmd` files rendered by CLI, express these as `classDef` lines at the end of the
source (light values shown; the CLI has no dark mode):

```
classDef hook fill:#E6F1FB,stroke:#185FA5,color:#0C447C
classDef effect fill:#E1F5EE,stroke:#0F6E56,color:#085041
classDef terminal fill:#F1EFE8,stroke:#5F5E5A,color:#2C2C2A
```

## Layout rules

**Graph tasks, table statuses.** A `stateDiagram-v2` with a dozen status edges across
five states produces overlapping edge labels in every layout engine. Consolidate edges
sharing a source and target into one labelled edge and let Table B carry the full list.
As a working threshold: more than two edges between the same pair of nodes means
consolidate.

**Direction.** Default to `TB`. Switch to `LR` when the graph is taller than roughly
600px — trading vertical stacking for width usually resolves label crowding on its own.

**Edge labels stay short.** Under about 40 characters. Longer labels are what force the
layout engine into the overlaps. Detail belongs in the tables.

**Batch jobs get the terminal class** in the event chain, so it is visible at a glance
that they are not triggered by user action.

**Never encode a transition that is not in Table B.** If it is not in the table, it did
not come from the source document.
