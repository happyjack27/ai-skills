---
name: mssql-dynamic-tables
description: 'SQL Server file tables and dynamic schema generation: using development.DynamicFile and development.DynamicSQUID procs to create file-storage tables with CRUD operations, persisted FK columns, indexes, triggers, and delete-tracking. Includes naming conventions for constraints, computed columns, and proc patterns. Use when creating new file tables (ProjectFile, ContractorFile, etc.) or understanding existing ones.'
---

# SQL Server Dynamic File Tables & Schema Generation

## Purpose

Help an AI generate standardized file-storage tables and CRUD procedures on SQL Server using established development schema generation procs, rather than writing table/proc DDL from scratch.

## Scope

**Included:**
- File table patterns: `development.DynamicFile` for table + trigger creation.
- CRUD code generation: `development.DynamicSQUID` for Insert/Select/SelectBy/Delete/Update/UpdatePK/SelectCount procedures.
- Naming conventions: FK constraints (`FK_[ParentTable]_[ReferencedTable]`), indexes (`IX_[Table]_[Column]`), persisted computed columns (`FK_[Parent]`).
- Delete tracking: AFTER DELETE triggers logging to `itmd.DeletedFile`.
- Reference pattern: `ContractorLienWavier` table as baseline for file tables.

**Out of scope:**
- Blob/FileStream storage in database (these tables reference fileshare paths only).
- Complex multi-parent file relationships (pattern assumes single FK_ID → one parent table).
- Non-file tables (use `sql` skill for general DDL).

## When to Use

- User needs a new file attachment table (ProjectFile, ContractorFile, AttachmentTable, etc.).
- User needs to understand the structure/procedures of existing file tables.
- User is validating that file tables have correct naming, indexes, and foreign keys.
- User needs CRUD procedures for a file table without writing manual proc DDL.

## Inputs Expected

| Input | Description | Example |
|---|---|---|
| Table name | Name of file table to create | `ProjectFile`, `ContractorFile` |
| FK table | Parent entity this file references | `Project`, `Contractor` |
| Database | Target SQL Server database with `development` schema | `MilwaukeeHealthyHomeProgram` |
| Verify indexes | Whether to check/create FK and computed-column indexes | Yes / No |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| File table | SQL table | 7-column schema: ID (PK), FK_ID, INSERT_DATE, FN_FILE_BYTES, CONTENT_TYPE, FILE_BYTES_PATH (computed), FK_[Parent] (computed persisted) |
| CRUD procedures | 7 SQL procs | Insert[Table], Select[Table], SelectByPK, Delete[Table]ByPK, Update[Table]ByPK, SelectCount[Table], Update[Table]PK |
| Triggers | AFTER DELETE trigger | Logs deleted file ID to `itmd.DeletedFile` with TableName='[schema].[TableName]' |
| Indexes | Nonclustered indexes | `IX_[Table]_FK_ID`, `IX_[Table]_FK_[Parent]` (if created) |
| FK constraints | 2 foreign keys | `FK_[Table]_[Parent]` (FK_ID), `FK_[Table]_[Parent]1` (FK_[Parent]) |

## Workflow

### Phase 1: Table Creation

1. **Connect to database** with `development` schema accessible (e.g., MilwaukeeHealthyHomeProgram, sql-dev).
2. **Execute DynamicFile**:
   ```sql
   EXEC development.DynamicFile 
     @Schema = 'dbo', 
     @Table = 'ProjectFile',           -- New table name
     @FKTable = 'Project',             -- Parent table
     @DebugPrint = 0, 
     @CreateTable = 1, 
     @IsFkBigInt = 0;
   ```
   - This creates the table with 7 columns and an AFTER DELETE trigger.
   - **Do NOT manually create the table or trigger** — DynamicFile handles both.

3. **Verify the table** exists with correct columns:
   ```sql
   SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.ProjectFile');
   ```
   Expected columns: ID, FK_ID, INSERT_DATE, FN_FILE_BYTES, CONTENT_TYPE, FILE_BYTES_PATH, FK_Project.

### Phase 2: CRUD Procedure Generation

4. **Execute DynamicSQUID**:
   ```sql
   EXEC development.DynamicSQUID 
     @Schema = 'dbo', 
     @Table = 'ProjectFile',
     @DebugPrint = 0, 
     @Delete = 1, 
     @Insert = 1, 
     @Select = 1, 
     @SelectBy = 1, 
     @Update = 1, 
     @UpdatePK = 1, 
     @DoDrops = 0;
   ```
   - This generates 7 procs: Insert, Select, SelectByPK, Delete, Update, SelectCount, UpdatePK.

5. **Verify procedures** exist:
   ```sql
   SELECT name FROM sys.objects 
   WHERE type = 'P' AND name LIKE 'Insert%' OR name LIKE 'Select%';
   ```

### Phase 3: Indexes & Foreign Keys

6. **List required indexes** using `development.AllIndexesCreate`:
   ```sql
   EXEC development.AllIndexesCreate;
   ```
   Look for rows with `AlreadyExists = 0` for your new table.

7. **Create missing indexes** (naming: `IX_[Table]_[Column]`):
   ```sql
   CREATE INDEX [IX_ProjectFile_FK_ID] ON [dbo].[ProjectFile]([FK_ID]);
   CREATE INDEX [IX_ProjectFile_FK_Project] ON [dbo].[ProjectFile]([FK_Project]);
   ```

8. **Create foreign keys** using `development.DynamicListFKConstraints` pattern:
   ```sql
   ALTER TABLE [dbo].[ProjectFile] WITH CHECK ADD CONSTRAINT [FK_ProjectFile_Project] 
     FOREIGN KEY ([FK_ID]) REFERENCES [dbo].[Project]([ID]);
   ALTER TABLE [dbo].[ProjectFile] CHECK CONSTRAINT [FK_ProjectFile_Project];
   
   ALTER TABLE [dbo].[ProjectFile] WITH CHECK ADD CONSTRAINT [FK_ProjectFile_Project1] 
     FOREIGN KEY ([FK_Project]) REFERENCES [dbo].[Project]([ID]);
   ALTER TABLE [dbo].[ProjectFile] CHECK CONSTRAINT [FK_ProjectFile_Project1];
   ```

9. **Verify indexes and FKs** against reference table:
   ```sql
   SELECT * FROM sys.indexes 
   WHERE object_id = OBJECT_ID('dbo.ProjectFile') ORDER BY name;
   
   SELECT * FROM sys.foreign_keys 
   WHERE parent_object_id = OBJECT_ID('dbo.ProjectFile');
   ```

## Column Details

| Column | Type | Default | Computed | Persisted | Purpose |
|--------|------|---------|----------|-----------|---------|
| ID | uniqueidentifier | NEWID() | No | No | Primary key; identifies file record |
| FK_ID | uniqueidentifier | (none) | No | No | Foreign key to parent table (Project, Contractor) |
| INSERT_DATE | datetime2 | GETDATE() | No | No | Timestamp of file upload |
| FN_FILE_BYTES | nvarchar(100) | (none) | No | No | Filename (e.g., "permit.pdf") |
| CONTENT_TYPE | nvarchar(100) | (none) | No | No | MIME type (e.g., "application/pdf") |
| FILE_BYTES_PATH | nvarchar(500) | (none) | Yes | Yes | Computed fileshare path; computed from schema/table/ID |
| FK_[Parent] | uniqueidentifier | (none) | Yes | Yes | Computed from FK_ID; supports indexed lookups without JOIN |

**Persisted computed columns** (`FK_[Parent]`) allow queries to filter without joining to the computed expression; SQL Server pre-calculates and stores them.

## Naming Conventions

| Object | Pattern | Example | Notes |
|--------|---------|---------|-------|
| File table | `[dbo].[TableName]` | `[dbo].[ProjectFile]` | Singular noun; follows parent entity |
| Primary key | System-generated | `PK__ProjectFile__3214EC27...` | Clustered index on ID |
| Computed column | `FILE_BYTES_PATH`, `FK_[Parent]` | `FILE_BYTES_PATH`, `FK_Project` | Constructed from standard template |
| FK constraint | `FK_[Table]_[Parent]` | `FK_ProjectFile_Project` | Both FK_ID and FK_[Parent] get constraints |
| FK index | `IX_[Table]_[Column]` | `IX_ProjectFile_FK_ID` | Nonclustered; one per FK column |
| Delete trigger | `DeletedFile_[Table]` | `DeletedFile_ProjectFile` | Auto-created by DynamicFile |

## Quality Standards

- **Always use DynamicFile and DynamicSQUID** — never write file table DDL or CRUD procs manually. Consistency depends on these generators.
- **Never skip Phase 3 (indexes & FKs)** — even if procs are working, missing indexes harm query performance and FK constraints ensure referential integrity.
- **Verify trigger exists** after running DynamicFile: `SELECT * FROM sys.triggers WHERE name LIKE 'DeletedFile_%'`.
- **Test CRUD procs** with a sample insert/select cycle before declaring the table production-ready.
- **Check collation on FK_[Parent] computed columns** — if it differs from the parent PK, computed value may not match in string comparisons.

## Common Mistakes

- **Running DynamicSQUID before DynamicFile** — DynamicSQUID expects the table to exist; you'll get "object does not exist" errors. Always run DynamicFile first.
- **Forgetting to run Phase 3** — CRUD procs work, but queries are slow and there's no data integrity if FKs and indexes are missing.
- **Editing DynamicFile output manually** — if you modify the generated table/trigger, re-running DynamicFile will fail because objects already exist. Use `@DoDrops=1` in DynamicSQUID or manually DROP before re-running.
- **Wrong @FKTable parameter** — if you pass `@FKTable = 'Projects'` (plural) instead of `'Project'`, the computed FK_[Parent] column and constraints will reference a nonexistent table. **Verify the parent table name first**.
- **Not comparing against ContractorLienWavier** — existing file tables (ContractorLienWavier) are the reference pattern. If your new table differs in index naming, FK naming, or column structure, suspect a parameter error or proc bug.

## Validation Checklist

- [ ] DynamicFile executed with `@CreateTable = 1` and no errors.
- [ ] Table exists with 7 columns: ID, FK_ID, INSERT_DATE, FN_FILE_BYTES, CONTENT_TYPE, FILE_BYTES_PATH, FK_[Parent].
- [ ] AFTER DELETE trigger exists and references `itmd.DeletedFile`.
- [ ] DynamicSQUID executed with all @Delete/@Insert/@Select/@SelectBy/@Update/@UpdatePK = 1.
- [ ] All 7 CRUD procs exist with correct naming.
- [ ] Nonclustered indexes created: `IX_[Table]_FK_ID` and `IX_[Table]_FK_[Parent]`.
- [ ] Two foreign keys created: one on FK_ID, one on FK_[Parent].
- [ ] Insert and Select procs tested with sample data.
- [ ] Table structure matches reference table (e.g., ContractorLienWavier) exactly.

## Examples

See `examples/`.

## References

- **DynamicFile proc** — Located in `development` schema; creates file table, persisted computed columns, AFTER DELETE trigger.
- **DynamicSQUID proc** — Located in `development` schema; generates CRUD procedures from table metadata.
- **AllIndexesCreate proc** — Lists required indexes for all FK and computed columns in dbo schema.
- **DynamicListFKConstraints proc** — Lists FK constraint creation statements with proper naming.
- **itmd.DeletedFile table** — Shared audit table; tracks deleted file records across all file tables.
- **ContractorLienWavier table** — Reference file table; use as baseline for validating new file tables.

## Related Skills

- [`../sql/SKILL.md`](../sql/SKILL.md) — General SQL query/DDL work.
- [`../java/SKILL.md`](../java/SKILL.md) — JDBC code that calls these CRUD procs.
