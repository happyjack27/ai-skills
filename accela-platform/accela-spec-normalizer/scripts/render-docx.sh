#!/usr/bin/env bash
# Stage 6: consolidate the normalized spec (header, gaps, Tables A-E, diagrams) into
# one reviewer-facing .docx. Never deletes or replaces the .md/.mmd/.svg deliverables -
# the .docx is a generated export, same rule as Stage 5's .svg.
set -euo pipefail
SRC="${1:-spec.md}"
DIR="$(dirname "$SRC")"
OUT="${SRC%.md}.docx"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc not found. Deliver the .md/.mmd/.svg files alone and say so."
  exit 1
fi

# Word needs a raster/vector pandoc can embed directly; bare .svg usually fails
# without rsvg-convert/inkscape/imagemagick installed. Render a .png copy per
# diagram just for embedding - the .svg stays the source of truth.
render_png() {
  local mmd="$1" png="$2" svg="$3"
  if command -v mmdc >/dev/null 2>&1; then
    mmdc -i "$mmd" -o "$png" -b transparent
  elif command -v npx >/dev/null 2>&1; then
    # No local mmdc install - npx fetches @mermaid-js/mermaid-cli on demand.
    # Works even where the Kroki HTTP fallback below is blocked, since it only
    # needs npm registry access, not arbitrary outbound HTTP.
    npx --yes @mermaid-js/mermaid-cli -i "$mmd" -o "$png" -b transparent
  elif [ -n "$svg" ] && command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert "$svg" -o "$png"
  elif command -v curl >/dev/null 2>&1; then
    curl -sf -X POST --data-binary "@$mmd" -H 'Content-Type: text/plain' \
      https://kroki.io/mermaid/png -o "$png" || echo "FAILED to render $png, embedding skipped"
  fi
}

shopt -s nullglob
for f in "$DIR"/diagrams/*.svg; do
  mmd="${f%.svg}.mmd"
  [ -e "$mmd" ] && render_png "$mmd" "${f%.svg}.png" "$f"
done

# Some diagrams never went through Stage 5's .mmd/.svg export and only exist as a
# fenced ```mermaid block inside a .md (this repo's convention for agent-viewable
# diagrams - see diagrams/RATIONALE.md). Extract the fence to a scratch .mmd and
# render that too, so Stage 6 doesn't silently skip them.
for f in "$DIR"/diagrams/*.md; do
  base="${f%.md}"
  [ -e "$base.svg" ] && continue
  mmd="$base.mmd"
  awk '/^```mermaid/{p=1;next}/^```/{p=0}p' "$f" > "$mmd"
  [ -s "$mmd" ] && render_png "$mmd" "$base.png" ""
  rm -f "$mmd"
done

pandoc "$SRC" --resource-path="$DIR:$DIR/diagrams" -o "$OUT"
echo "rendered $OUT"
