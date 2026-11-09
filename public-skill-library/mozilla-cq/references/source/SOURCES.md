# Mozilla cq local source copies

Snapshots taken 2026-11-09 from the `main` branch of https://github.com/mozilla-ai/cq for offline search. The upstream repository is authoritative. Re-fetch before relying on flags, since cq is version 0.x.

| File | Origin | SHA-256 |
|---|---|---|
| `install.md` | https://github.com/mozilla-ai/cq/blob/main/docs/install.md | 961ba247c35ae110277b6af4b0e548444f71133c33feb501a1c5fab70d96ef30 |
| `upstream-cq-SKILL.md` | https://github.com/mozilla-ai/cq/blob/main/plugins/cq/skills/cq/SKILL.md (upstream plugin skill, not installed by this library) | 38c74238c0516b911a3689d28e072a7132e1a434558306f9ba93bf26f8ed152a |
| `LICENSE` | https://github.com/mozilla-ai/cq/blob/main/LICENSE | 36558d503a3d8ff7a6fa45f0f7b7b8b5419b34ad8ee97707ae07465676db4a1c |

License: Apache-2.0 (copy of the upstream `LICENSE` file included). Keep the license with any redistributed copy.

Search offline with `grep -n "<term>" *.md`, then use [api-reference.md](../api-reference.md) for the exact flags. `upstream-cq-SKILL.md` is reference only. Do not install it alongside `mozilla-cq` without approval.
