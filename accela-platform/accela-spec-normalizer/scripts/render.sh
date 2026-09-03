#!/usr/bin/env bash
# Render every .mmd in a directory to .svg.
# Mermaid source is the source of truth; SVG is a generated artifact.
set -euo pipefail
DIR="${1:-diagrams}"
shopt -s nullglob
FILES=("$DIR"/*.mmd)
if [ ${#FILES[@]} -eq 0 ]; then echo "No .mmd files in $DIR"; exit 1; fi

if command -v mmdc >/dev/null 2>&1; then
  for f in "${FILES[@]}"; do
    mmdc -i "$f" -o "${f%.mmd}.svg" -b transparent
    echo "rendered ${f%.mmd}.svg"
  done
  exit 0
fi

if command -v curl >/dev/null 2>&1; then
  echo "mmdc not found, falling back to Kroki"
  for f in "${FILES[@]}"; do
    if curl -sf -X POST --data-binary "@$f" \
        -H 'Content-Type: text/plain' \
        https://kroki.io/mermaid/svg -o "${f%.mmd}.svg"; then
      echo "rendered ${f%.mmd}.svg"
    else
      echo "FAILED ${f} - deliver the .mmd as-is and say so"
    fi
  done
  exit 0
fi

echo "Neither mmdc nor curl available. Deliver the .mmd files and tell the user"
echo "the SVG export could not run - do not silently skip it."
exit 1
