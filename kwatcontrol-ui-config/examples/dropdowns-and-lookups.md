# Example: Creating and Using Dropdowns

## Context

**Application:** All apps using KWATControl  
**Database:** KWATControl (on sql-itmd)  
**Task:** Create a "ContractorStatus" dropdown with values Active, Inactive, Suspended, and link it to the Contractor.Status field.  
**Reason:** Provide consistent, validated status values across the UI instead of free-text input.

## Step 1: Create the Dropdown Category and Values

```sql
USE KWATControl;
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
('ContractorStatus', 'ACTIVE', 'Active'),
('ContractorStatus', 'INACTIVE', 'Inactive'),
('ContractorStatus', 'SUSPENDED', 'Suspended');
```

**Explanation:**
- **CATEGORY**: Grouping name; any column using `DropdownSource='ContractorStatus'` will reference these rows.
- **KEY**: Internal value (stored in database). Use UPPERCASE for clarity; must be unique within the category.
- **VALUE**: Display label shown in the UI dropdown; can have spaces and mixed case.

## Step 2: Verify the Dropdown was Created

```sql
SELECT ID, CATEGORY, KEY, VALUE
FROM dbo.APP_DROPDOWNS
WHERE CATEGORY = 'ContractorStatus'
ORDER BY KEY;
```

**Expected Result:**
```
ID   CATEGORY           KEY        VALUE
===  =================  =========  ===========
1    ContractorStatus   ACTIVE     Active
2    ContractorStatus   INACTIVE   Inactive
3    ContractorStatus   SUSPENDED  Suspended
```

## Step 3: Find the Contractor.Status Column

Assume the underlying Contractor table has a column called `Status` that we want to make a dropdown.

```sql
SELECT ColumnID, TableID, ColumnName, DisplayName, DataType, DropdownSource
FROM dbo.APP_TABLE_COLUMNS
WHERE ColumnName = 'Status' AND ColumnID IN (
  SELECT ColumnID FROM dbo.APP_TABLE_COLUMNS
  WHERE TableID = (SELECT TableID FROM dbo.APP_TABLES WHERE TableName = 'Contractor')
);
```

**Result:** ColumnID = 123, TableID = 42

## Step 4: Link the Dropdown to the Status Column

```sql
UPDATE dbo.APP_TABLE_COLUMNS
SET DataType = 'dropdown', DropdownSource = 'ContractorStatus'
WHERE ColumnID = 123;
```

## Step 5: Verify the Column is Now a Dropdown

```sql
SELECT ColumnID, ColumnName, DisplayName, DataType, DropdownSource, Visible, Active
FROM dbo.APP_TABLE_COLUMNS
WHERE ColumnID = 123;
```

**Expected Result:**
```
ColumnID  ColumnName  DisplayName  DataType   DropdownSource     Visible  Active
=========  ==========  ===========  =========  =================  =======  ======
123        Status      Status       dropdown   ContractorStatus   1        1
```

## Step 6: Test in UI

1. Navigate to the KWAT Contractor table view.
2. Click on a Status field; it should show a dropdown with: **Active**, **Inactive**, **Suspended**.
3. Select one; the value is saved to the database as the KEY (e.g., 'ACTIVE').
4. Verify the selected value persists when you reload the page.

## Step 7: Add More Dropdown Values (Later)

If you need to add "OnHold" status later:

```sql
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
('ContractorStatus', 'ONHOLD', 'On Hold');
```

The dropdown automatically includes the new value the next time users load the page (no UI code change needed).

## Step 8: Remove/Disable a Dropdown Value

**Option A: Disable (recommended)** — add an Active column if the table supports it, or use a convention:

```sql
-- Rename the VALUE to indicate it's deprecated:
UPDATE dbo.APP_DROPDOWNS
SET VALUE = '[DEPRECATED] Suspended'
WHERE CATEGORY = 'ContractorStatus' AND KEY = 'SUSPENDED';
```

**Option B: Delete** — only if you're certain no records use this value:

```sql
DELETE FROM dbo.APP_DROPDOWNS
WHERE CATEGORY = 'ContractorStatus' AND KEY = 'SUSPENDED';
```

## Common Patterns

### Pattern: Yes/No or True/False Dropdowns

```sql
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
('YesNo', 'Y', 'Yes'),
('YesNo', 'N', 'No');
```

Then link to any boolean-like column:
```sql
UPDATE dbo.APP_TABLE_COLUMNS
SET DataType = 'dropdown', DropdownSource = 'YesNo'
WHERE ColumnID = (SELECT ColumnID FROM dbo.APP_TABLE_COLUMNS WHERE ColumnName = 'IsActive');
```

### Pattern: Lookup Table Dropdown

If your dropdown values come from another database table (e.g., Cities from a Cities table), populate APP_DROPDOWNS periodically via an ETL job or manual sync:

```sql
-- Sync cities from dbo.Cities:
DELETE FROM dbo.APP_DROPDOWNS WHERE CATEGORY = 'City';
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE)
SELECT 'City', CityCode, CityName FROM [source_database].dbo.Cities WHERE Active = 1;
```

### Pattern: Multi-Level Dropdowns (if supported)

Some UIs support hierarchical dropdowns (e.g., State → County). If your APP_DROPDOWNS table has a ParentKey column:

```sql
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE, ParentKey) VALUES
('County', 'DANE', 'Dane County', 'WI'),
('County', 'MILL', 'Milwaukee County', 'WI'),
('State', 'WI', 'Wisconsin', NULL);
```

Check your app's UI documentation to confirm support.

## Troubleshooting

**Symptom:** Dropdown shows up but no values appear.

**Cause:** DropdownSource name doesn't match a CATEGORY in APP_DROPDOWNS (typo or not yet created).

**Fix:** 
```sql
-- Verify the dropdown exists:
SELECT DISTINCT CATEGORY FROM dbo.APP_DROPDOWNS 
WHERE CATEGORY LIKE '%Status%';

-- Verify the column's DropdownSource matches:
SELECT ColumnName, DropdownSource FROM dbo.APP_TABLE_COLUMNS 
WHERE ColumnID = 123;
```

**Symptom:** Old dropdown values still showing after I added new ones.

**Cause:** Browser cache.

**Fix:** Hard-refresh the page (Ctrl+Shift+R or Cmd+Shift+R) to clear cache.

**Symptom:** Dropdown works in UI but database still stores old free-text values.

**Cause:** Data migration wasn't done. Existing Contractor.Status values may be free-text; new values will be constrained by the dropdown.

**Fix:** Migrate old data to valid KEY values:
```sql
UPDATE dbo.Contractor
SET Status = 'ACTIVE'
WHERE Status LIKE '%active%' OR Status LIKE '%true%';

UPDATE dbo.Contractor
SET Status = 'INACTIVE'
WHERE Status LIKE '%inactive%' OR Status LIKE '%false%';
```

## Key Points

- **APP_DROPDOWNS is shared across all applications** — use a descriptive CATEGORY name to avoid conflicts (e.g., "ContractorStatus" vs. just "Status").
- **KEY must be unique within each CATEGORY** — duplicate KEYs in the same CATEGORY will cause unpredictable dropdown behavior.
- **VALUE can have duplicates** — but it's confusing; prefer unique display labels.
- **Dropdowns are cached at application startup** — if a web app caches dropdowns in memory, new values may not show until the app restarts.
- **No referential integrity** — APP_DROPDOWNS is independent from APP_TABLE_COLUMNS; deleting a dropdown doesn't delete corresponding columns, so verify before cleanup.
