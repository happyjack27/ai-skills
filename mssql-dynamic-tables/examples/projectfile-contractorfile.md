# Example: ProjectFile and ContractorFile Tables

## Context

**Database:** `MilwaukeeHealthyHomeProgram` (sql-dev)  
**Parent Tables:** `dbo.Project`, `dbo.Contractor`  
**Goal:** Create file-attachment tables following the `ContractorLienWavier` pattern.

## Step 1: Create ProjectFile Table

```sql
EXEC development.DynamicFile 
  @Schema = 'dbo', 
  @Table = 'ProjectFile',
  @FKTable = 'Project',
  @DebugPrint = 0, 
  @CreateTable = 1, 
  @IsFkBigInt = 0;
```

**Result:** Table created with these columns:
- `ID` (uniqueidentifier, PK, NEWID default)
- `FK_ID` (uniqueidentifier, NOT NULL; foreign key to Project.ID)
- `INSERT_DATE` (datetime2, GETDATE default)
- `FN_FILE_BYTES` (nvarchar(100); filename)
- `CONTENT_TYPE` (nvarchar(100); MIME type)
- `FILE_BYTES_PATH` (nvarchar(500), computed; fileshare path)
- `FK_Project` (uniqueidentifier, computed persisted; duplicate of FK_ID for query optimization)

**Trigger Created:** `DeletedFile_ProjectFile` (AFTER DELETE) → logs to `itmd.DeletedFile`

## Step 2: Generate CRUD Procedures for ProjectFile

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

**Procedures Generated:**
1. `InsertProjectFile` — Insert new file record
2. `SelectProjectFile` — Select with optional filtering (FK_ID, INSERT_DATE range, filename pattern)
3. `SelectProjectFileByPK` — Get by ID
4. `DeleteProjectFileByPK` — Delete by ID (triggers after-delete to itmd.DeletedFile)
5. `UpdateProjectFileByPK` — Update filename/content-type by ID
6. `SelectCountProjectFile` — Row count (useful for pagination)
7. `UpdateProjectFilePK` — Update primary key (rare use case)

## Step 3: Create Indexes and Foreign Keys

### List Required Indexes
```sql
EXEC development.AllIndexesCreate;
```

**Output for ProjectFile (AlreadyExists = 0):**
```
CREATE INDEX [IX_ProjectFile_FK_ID] ON [ProjectFile]([FK_ID]);
CREATE INDEX [IX_ProjectFile_FK_Project] ON [ProjectFile]([FK_Project]);
```

### Execute Index Creation
```sql
CREATE INDEX [IX_ProjectFile_FK_ID] ON [dbo].[ProjectFile]([FK_ID]);
CREATE INDEX [IX_ProjectFile_FK_Project] ON [dbo].[ProjectFile]([FK_Project]);
```

### Create Foreign Keys
```sql
ALTER TABLE [dbo].[ProjectFile] WITH CHECK ADD CONSTRAINT [FK_ProjectFile_Project] 
  FOREIGN KEY ([FK_ID]) REFERENCES [dbo].[Project]([ID]);
ALTER TABLE [dbo].[ProjectFile] CHECK CONSTRAINT [FK_ProjectFile_Project];

ALTER TABLE [dbo].[ProjectFile] WITH CHECK ADD CONSTRAINT [FK_ProjectFile_Project1] 
  FOREIGN KEY ([FK_Project]) REFERENCES [dbo].[Project]([ID]);
ALTER TABLE [dbo].[ProjectFile] CHECK CONSTRAINT [FK_ProjectFile_Project1];
```

## Step 4: Verify Structure

### Verify Columns
```sql
SELECT name, system_type_name, is_nullable, is_computed
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.ProjectFile')
ORDER BY column_id;
```

**Expected:**
```
ID                   uniqueidentifier  0  0
FK_ID                uniqueidentifier  0  0
INSERT_DATE          datetime2(7)      1  0
FN_FILE_BYTES        nvarchar(100)     0  0
CONTENT_TYPE         nvarchar(100)     0  0
FILE_BYTES_PATH      nvarchar(500)     1  1
FK_Project           uniqueidentifier  1  1
```

### Verify Indexes
```sql
SELECT i.name, i.type_desc, i.is_primary_key
FROM sys.indexes i
WHERE object_id = OBJECT_ID('dbo.ProjectFile')
ORDER BY i.name;
```

**Expected:**
```
IX_ProjectFile_FK_ID        NONCLUSTERED  0
IX_ProjectFile_FK_Project   NONCLUSTERED  0
PK__ProjectFile__...        CLUSTERED     1
```

### Verify Foreign Keys
```sql
SELECT fk.name, c.name AS parent_column, tr.name AS referenced_table
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.ProjectFile')
ORDER BY fk.name;
```

**Expected:**
```
FK_ProjectFile_Project      FK_ID        Project
FK_ProjectFile_Project1     FK_Project   Project
```

## Step 5: Test CRUD Operations

### Insert a File
```sql
DECLARE @ProjectID uniqueidentifier = (SELECT TOP 1 ID FROM dbo.Project);
EXEC InsertProjectFile @FK_ID = @ProjectID, @FN_FILE_BYTES = 'permit.pdf', @CONTENT_TYPE = 'application/pdf';
```

### Select Files for a Project
```sql
EXEC SelectProjectFile @FK_ID = @ProjectID;
```

### Select by Primary Key
```sql
DECLARE @FileID uniqueidentifier = (SELECT TOP 1 ID FROM dbo.ProjectFile);
EXEC SelectProjectFileByPK @ID = @FileID;
```

### Update File Metadata
```sql
EXEC UpdateProjectFileByPK @ID = @FileID, @FN_FILE_BYTES = 'permit_revised.pdf', @CONTENT_TYPE = 'application/pdf';
```

### Delete File (triggers itmd.DeletedFile logging)
```sql
EXEC DeleteProjectFileByPK @ID = @FileID;
-- Verify it was logged:
SELECT * FROM itmd.DeletedFile WHERE TableName = '[dbo].[ProjectFile]';
```

## Step 6: Repeat for ContractorFile

Apply the same workflow with:
- `@Table = 'ContractorFile'`
- `@FKTable = 'Contractor'`

Result: Identical structure, naming, procs, and triggers for contractor file attachments.

## Final Validation: Compare Against Reference

```sql
SELECT 
  t.name AS table_name,
  COUNT(c.column_id) AS column_count
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE t.name IN ('ProjectFile', 'ContractorFile', 'ContractorLienWavier')
GROUP BY t.name
ORDER BY t.name;
```

**Expected:** All three tables have 7 columns.

```sql
SELECT t.name, COUNT(i.index_id) AS index_count
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name IN ('ProjectFile', 'ContractorFile', 'ContractorLienWavier')
GROUP BY t.name
ORDER BY t.name;
```

**Expected:** ProjectFile and ContractorFile each have 3 indexes (1 clustered PK + 2 nonclustered FK indexes); ContractorLienWavier has 3.

```sql
SELECT t.name, COUNT(fk.object_id) AS fk_count
FROM sys.tables t
LEFT JOIN sys.foreign_keys fk ON t.object_id = fk.parent_object_id
WHERE t.name IN ('ProjectFile', 'ContractorFile', 'ContractorLienWavier')
GROUP BY t.name
ORDER BY t.name;
```

**Expected:** ProjectFile and ContractorFile each have 2 foreign keys; ContractorLienWavier has 2.

## Common Pitfalls (What We Learned)

1. **DynamicSQUID before DynamicFile** → Error "object does not exist". Always run DynamicFile first.
2. **Missing Phase 3 (indexes/FKs)** → CRUD procs work but queries are slow; no referential integrity.
3. **Wrong parent table name** → e.g., `@FKTable = 'Projects'` instead of `'Project'` → computed columns and FKs fail.
4. **Manual edits after DynamicFile** → Re-running generators fails because objects exist. Use `@DoDrops=1` if you need to regenerate.

## Success Criteria

- ✓ Table exists with 7 columns (matching ContractorLienWavier exactly).
- ✓ All 7 CRUD procs exist and are callable.
- ✓ After-delete trigger exists and logs to `itmd.DeletedFile`.
- ✓ 2 nonclustered indexes created on FK columns.
- ✓ 2 foreign keys created with correct naming (`FK_[Table]_[Parent]` pattern).
- ✓ Sample insert/select/delete operations execute without error.
- ✓ Structure validated against reference table (ContractorLienWavier).
