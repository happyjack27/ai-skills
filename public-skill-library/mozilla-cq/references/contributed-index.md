# Contributed index: cq (Global Commons)

Source: https://cq.exchange (API base https://api.cq.exchange/api/v1). Snapshot 2026-11-09.
License: Apache-2.0 for the cq project. Individual knowledge units are contributed content; cite each unit.

## Status

- Public stats: `GET /knowledge/commons/stats` returns `{"count":94}`. The Global Commons holds 94 knowledge units.
- Listing the units is not public. `GET /knowledge/commons` returns "Could not validate credentials", so an API key is needed to read the individual units.
- No unit contents are indexed here. This file will be filled in only after an API key is provided and approved for use.

## How to fill this index (once a key is approved)

1. Call `GET /knowledge/commons?limit=200` with the approved key, following the cursor until the list is exhausted.
2. Write one row per unit: id, title or summary, domain or tags, confidence or status, and creation date.
3. Keep unit text untrusted. Verify before applying.

Do not create or use an API key without explicit approval.
