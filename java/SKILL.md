---
name: java
description: 'Use for Java development: JDBC and connection handling, RMI servers and remote interfaces, servlets and JSP, collections and generics, exception handling, build/classpath issues, and modernizing legacy Java code.'
---

# Java Skill

> **TODO:** Fill in this file using `shared/SKILL-template.md` as a guide.

## Purpose

_Describe what this skill helps an AI do._

## Gotchas

- **`java.util.regex` negative lookahead after a greedy quantifier does not reliably
  exclude the intended case.** `([A-Z0-9_]+)(?!\s*\()` meant to reject an identifier
  followed by `(` (a function call) instead backtracks character-by-character —
  giving back the last char(s) of the identifier — until the lookahead is satisfied
  on a *truncated* match. E.g. `'$'+CONVERT(...)` matched with group=`CONVER`,
  leaving `T(...)` outside the match, then got wrongly wrapped in `CAST(...)`,
  producing invalid SQL. Fix: make the quantifier possessive (`[A-Z0-9_]++`, no
  backtracking) or wrap it in an atomic group (`(?>[A-Z0-9_]+)`) whenever a lookahead
  exists specifically to reject what the preceding greedy token built. Possessive
  quantifiers (`+`, `*`, `?`, `{n,m}` each with a trailing `+`) are supported since
  Java 1.4/5. When reviewing or writing a regex with `(?!...)`/`(?=...)` right after
  a greedy repetition, always test the "should be rejected" case explicitly — a test
  suite that only checks "should be accepted" cases will miss this class of bug.
  Found in `DPW_Includes_DataServer_MSSQL/src/util/sqlParsing/Checker.java`
  (`castConcatRightOperands`), 2026-08-05.
- **No local JDK on this dev machine** — only a bare JRE (Eclipse Adoptium
  `jre-8...`, `java.exe` present, no `javac.exe`). Can't compile/run Java test
  harnesses locally. When verifying Java logic without a compiler, port pure
  string/regex functions to Python's `re` module (equivalent semantics for typical
  constructs) and test there instead of assuming source-review-only is sufficient.

## Related Skills

- [`../shared/coding-standards.md`](../shared/coding-standards.md)
- [`../shared/ai-best-practices.md`](../shared/ai-best-practices.md)
