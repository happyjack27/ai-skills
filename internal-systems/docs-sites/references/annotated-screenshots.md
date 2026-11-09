# Annotated screenshots

Use for end-user guides (and developer pages where a screen matters). Every control a reader must find gets a red box, plus either a numbered marker or a short arrow label. Step instructions and lists go in the page text under the picture, never inside the image. Verified 2026-11-05 on the EndUserDocumentation viewer through the browser tools.

## Rules

- Use a staging or practice copy, or the environment the user names. Do not capture real citizen, employee, or case data; use test records or blank fields.
- Capture the signed-in state the page needs, and say so in the caption ("signed in as an ITMD Developers member").
- Re-read the live DOM for each selector before drawing. Do not reuse coordinates from an earlier layout.
- Overlay coordinates are viewport coordinates (`position:fixed`). Crop after the capture if needed, but do not offset the overlay.
- Shapes: red box for a control or group of controls, optionally a small filled numbered circle at the control.
- The dividing line:
  - ALLOWED in the image: red boxes, numbered circle markers, and red arrows pointing at a control with a short label (1 to 3 words, for example "Edit emails"). Arrows with short labels are preferred.
  - NOT ALLOWED in the image: numbered or bulleted lists, sentences, instructions, captions, white bands, padding, or any expansion of the canvas to fit text. A text list belongs in the page body under the picture.
- Arrows must start at the label and end at the box edge, so the reader can tell which control each word refers to.
- Put every explanation in the Markdown body as real text: a numbered list or table directly under the image's step. Never bake instructions into the PNG.
- Image size: save at the capture's native pixel size (100%). Never enlarge (no 2× or upscaling). For emails and pages where a tall capture dominates the reading view, shrink the display, not the file: set `width="340"` on the `<img>` (keeps the aspect ratio and the native PNG). Only resize the PNG itself if the user asks. Do not add borders or padding. Do not resize or re-annotate an image the user has approved unless they ask. Before changing any approved image, back it up and get explicit approval for the new size.
- Approved look for end-user guides: red arrows with a short numbered label (for example "1. Enter your email address") and red boxes around controls. The text lives in the page or draft body, not in the picture.
- Remove the overlay after each capture, then check the saved PNG with the `view` tool before publishing it. Redo any image with a clipped label or an arrow that misses its target.
- Put the PNG in the topic's `images\` folder with a descriptive kebab-case name (`search-scope.png`). Reference it with a relative link, and explain each number in text directly below the picture.

## Procedure

1. Open the page in the browser tool and call `page.evaluate` to confirm each selector exists. A missing selector throws, so fix the selector before drawing.
2. Draw the overlay and capture with `page.screenshot({ path })` in the same run:

```javascript
const items = [
  { sel: '#docSearchBox', n: '1', text: 'Search box', shape: 'box', pos: 'below' },
  { sel: 'button[aria-label*="theme" i]', n: '2', text: 'Light/dark switch', shape: 'circle', pos: 'below' }
];
await page.evaluate((items) => {
  const NS = 'http://www.w3.org/2000/svg';
  const ov = document.createElement('div');
  ov.id = '__ann';
  ov.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483647';
  const svg = document.createElementNS(NS, 'svg');
  svg.setAttribute('width', '100%'); svg.setAttribute('height', '100%');
  svg.style.cssText = 'position:absolute;inset:0;overflow:visible';
  svg.innerHTML = '<defs><marker id="ah" markerWidth="10" markerHeight="10" refX="8" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#d7263d"/></marker></defs>';
  ov.appendChild(svg); document.body.appendChild(ov);
  for (const it of items) {
    const el = document.querySelector(it.sel);
    if (!el) throw new Error('missing ' + it.sel);
    const b = el.getBoundingClientRect();
    const shape = document.createElement('div');
    const size = it.shape === 'circle' ? Math.max(b.width, b.height) + 14 : 0;
    const w = it.shape === 'circle' ? size : b.width + 6;
    const h = it.shape === 'circle' ? size : b.height + 6;
    const cx0 = b.x + b.width / 2, cy0 = b.y + b.height / 2;
    shape.style.cssText = `position:absolute;left:${cx0 - w / 2}px;top:${cy0 - h / 2}px;width:${w}px;height:${h}px;border:3px solid #d7263d;border-radius:${it.shape === 'circle' ? '50%' : '6px'};box-sizing:border-box`;
    ov.appendChild(shape);
    const lb = document.createElement('div');
    lb.style.cssText = 'position:absolute;background:#d7263d;color:#fff;font:600 13px/1.3 Segoe UI,Arial,sans-serif;padding:4px 8px;border-radius:4px;white-space:nowrap';
    lb.textContent = it.n + '  ' + it.text;
    ov.appendChild(lb);
    const lw = lb.offsetWidth, lh = lb.offsetHeight;
    let lx, ly;
    if (it.pos === 'above') { lx = b.x; ly = b.y - lh - 22; }
    else if (it.pos === 'right') { lx = b.right + 30; ly = cy0 - lh / 2; }
    else if (it.pos === 'left') { lx = b.x - lw - 30; ly = cy0 - lh / 2; }
    else { lx = b.x; ly = b.bottom + 22; }
    lx = Math.max(4, Math.min(lx, innerWidth - lw - 4));
    ly = Math.max(4, Math.min(ly, innerHeight - lh - 4));
    lb.style.left = lx + 'px'; lb.style.top = ly + 'px';
    // Arrow runs from the label centre to the shape's edge.
    const sx = lx + lw / 2, sy = ly + lh / 2;
    const dx = sx - cx0, dy = sy - cy0;
    const rx = w / 2, ry = h / 2;
    const s = it.shape === 'circle'
      ? 1 / Math.sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry))
      : Math.min(dx ? rx / Math.abs(dx) : Infinity, dy ? ry / Math.abs(dy) : Infinity);
    const ex = cx0 + dx * s, ey = cy0 + dy * s;
    const line = document.createElementNS(NS, 'line');
    line.setAttribute('x1', sx); line.setAttribute('y1', sy);
    line.setAttribute('x2', ex); line.setAttribute('y2', ey);
    line.setAttribute('stroke', '#d7263d'); line.setAttribute('stroke-width', '3');
    line.setAttribute('marker-end', 'url(#ah)');
    svg.appendChild(line);
  }
}, items);
await page.screenshot({ path: 'C:\\path\\to\\topic\\images\\name.png' });
await page.evaluate(() => document.getElementById('__ann')?.remove());
```

3. Open the PNG with `view`. Check that each arrow ends on its shape, no label is cut off, and the numbers match the table.

## Pitfalls seen

- The embedded browser pane is smaller than a desktop window (for example 1274×606 or 546×600). Captures are cropped strips. Ask the user to enlarge the pane when a full-width picture matters. A `setViewportSize` call does not resize the pane.
- A label drawn with `max-width` wraps or clips. Keep labels `white-space:nowrap`.
- Clip-based offsets are wrong for a `position:fixed` overlay. Use viewport coordinates.
- Hover-only or menu-only controls (scope menu, tooltips) need the menu opened before the capture, in the same run.
- Pages in the lightbox or with a pager change height as they load. Wait for the page to settle, then draw.
- Never upload a test file to production for a screenshot. Show the Attach control and describe the file chooser in text.
- Labels that sit on a button or at the right edge of a pane (scrollbar clips them) are hidden or cut off. Put labels in empty space: the row beside the Tags, or above a heading. Keep arrows short and horizontal so they do not cross text.
- A live-preview test that edits the page must restore the source. Use `cm.replaceRange` to insert the test text, wait about 3 s, then `cm.undo()` until `cm.getValue()` equals the saved original. Verify the text matches. Never save.
- Save is disabled (opacity 0.5) with no changes. Typing enables it and the status reads "Unsaved changes". Capture that state after a test edit, then undo it.
- Hidden duplicate status elements have zero size. Filter them with `getBoundingClientRect().width > 0` before reading positions.

## Browser handling

- Do not navigate a tab the user has open or has shared with you. Navigating it with `page.goto` changed the user's window and can drop an unsaved edit, which the viewer's `beforeunload` prompt is meant to catch. Open a new tab with `openBrowserPage({ url, forceNew: true })` for capture work, and close it afterward.
- Check the viewport size before drawing (`innerWidth`, `innerHeight`). Reuse a wide tab for captures; a narrow tab gives cropped, unusable images.
- Sign-in on a LoginMKE page belongs to the user. The click on "Sign in to edit" timed out because the link was not stable, and the user must sign in. Ask them to sign in, then continue. Do not enter credentials.
- Edit-mode captures need a signed-in session; read-mode captures do not. Say which one each picture shows.
