---
name: webapp-docs
description: 'Create a compact web application documentation set with two core artifacts: the schema/ERD view and the use-case/test-case flow diagrams.'
---

# Webapp documentation skill

This skill supports a minimal documentation package for a web application with exactly two outputs:

1. the core database schema / ERD view
2. the main use-case flow diagrams, which also serve as the test-case baseline

## Purpose

Use this skill when the team needs a compact view of the app without creating redundant project documentation.

## Scope

Included:
- Core schema / ERD documentation
- Business entity relationship diagrams
- Main use-case flow diagrams
- Use cases that also act as acceptance/test scenarios

Not included:
- Generic design spec documents
- Requirements summaries
- Acceptance checklists
- Extra process paperwork

## Lookup / dropdown table rule

Do not include lookup or dropdown tables in the core schema overview when the table is clearly a catalog-style reference table.

Indicators that a table is a lookup/dropdown:
- it has a very small shape, usually a few columns only
- it contains an `ID` and `Label` pair
- it often has `Active`, `SortOrder`, or `OrderBy` fields
- it exists primarily to populate a list or select box in the UI
- it does not represent a business workflow or domain record with lifecycle behavior

Examples of this pattern include tables such as:
- Status
- Quarter
- ContactPreference
- AgeOfProperty
- PropertyUnit if it is used only as a selectable reference value

These tables should be excluded from the main ERD and kept out of the schema overview to avoid clutter and to keep the diagram focused on workflow records rather than reference lists.

## Foreign-key fidelity rule

The core ERD must reflect the actual foreign-key constraints in the database. Do not invent, infer, or "pretty up" relationships from UI labels, menu structure, or app assumptions.

Requirements:
- use actual FK relationships from the schema as the source of truth
- only include relationships that are supported by real foreign keys or clear existing DB linkage
- treat UI navigation, side menus, and domain labels as secondary evidence only
- if a relation is not backed by a real FK, do not add it to the core ERD
- if the app menu suggests a table exists but the database does not enforce the relationship, do not present it as part of the core schema

This rule is stricter than a conceptual "business relationship" diagram. The ERD is documentation of the database, not a guessed workflow model.

## Preferred output set

Keep the package to exactly two parts:

1. Core database schema / ERD
2. Main use cases (with success and failure paths)

This is enough to understand the system and validate behavior.

## Recommended workflow

1. Identify the main business entities and their relationships.
2. Build the compact ERD around the core tables and ignore lookup/reference clutter.
3. Identify the main user stories and workflow paths.
4. Turn each major workflow into a use-case diagram with actors, steps, decisions, and outcomes.
5. Use the same flow diagrams as the test-case baseline.

## What a use case should include

A use-case diagram should answer:
- who starts the flow
- what the goal is
- what happens next
- what decision points exist
- what the success and failure outcomes are

## Core rule

The deliverable is not a vague design specification. The real value is in the schema view and the behavior flows.

## References

Use the ERD files and the use-case flow diagrams as the canonical documentation package.
