# Example: Adding Email and Services Columns to Contractor Table

## Context

**Application:** KWAT (main web app)  
**Database:** KWATControl (on sql-itmd)  
**Task:** Add EmailAddress and ServicesProvided columns to the Contractor table UI.  
**Reason:** Business requirement to display contractor contact info and services in the UI.

## Step 1: Identify the TableID

```sql
USE KWATControl;
SELECT TableID, TableName, DisplayName, Active
FROM dbo.APP_TABLES
WHERE TableName = 'Contractor';
```

**Result:** TableID = 42 (example ID; actual ID may vary)

## Step 2: View Existing Columns

```sql
SELECT ColumnID, ColumnName, DisplayName, ColumnOrder, Visible, Editable, Active
FROM dbo.APP_TABLE_COLUMNS
WHERE TableID = 42
ORDER BY ColumnOrder;
```

**Result:**
```
ColumnID  ColumnName           DisplayName          ColumnOrder  Visible  Editable  Active
=========  ===================  ===================  ===========  =======  ========  ======
1          ID                   Contractor ID        1            1        0         1
2          Label                Contractor Name      2            1        1         1
3          Active               Status               3            1        1         1
4          OrderBy              Sort Order           4            0        1         1
5          FK_ContractorCompany Company ID           5            1        0         1
```

The current max ColumnOrder is 5, so new columns should start at 6.

## Step 3: Add EmailAddress Column

```sql
INSERT INTO dbo.APP_TABLE_COLUMNS (
  TableID,
  ColumnName,
  DisplayName,
  DataType,
  ColumnOrder,
  Visible,
  Editable,
  Required,
  Sortable,
  Filterable,
  MaxLength,
  HelpText,
  Active
) VALUES (
  42,
  'EmailAddress',
  'Email Address',
  'nvarchar',
  6,
  1,
  1,
  0,
  1,
  1,
  100,
  'Contractor contact email address',
  1
);
```

## Step 4: Add ServicesProvided Column

```sql
INSERT INTO dbo.APP_TABLE_COLUMNS (
  TableID,
  ColumnName,
  DisplayName,
  DataType,
  ColumnOrder,
  Visible,
  Editable,
  Required,
  Sortable,
  Filterable,
  MaxLength,
  HelpText,
  Active
) VALUES (
  42,
  'ServicesProvided',
  'Services Provided',
  'nvarchar',
  7,
  1,
  1,
  0,
  1,
  1,
  500,
  'Description of services this contractor provides (e.g., Plumbing, HVAC, Lead abatement)',
  1
);
```

## Step 5: Verify the Changes

```sql
SELECT ColumnID, ColumnName, DisplayName, ColumnOrder, Visible, Editable, Active
FROM dbo.APP_TABLE_COLUMNS
WHERE TableID = 42
ORDER BY ColumnOrder;
```

**Expected Result:**
```
ColumnID  ColumnName           DisplayName          ColumnOrder  Visible  Editable  Active
=========  ===================  ===================  ===========  =======  ========  ======
1          ID                   Contractor ID        1            1        0         1
2          Label                Contractor Name      2            1        1         1
3          Active               Status               3            1        1         1
4          OrderBy              Sort Order           4            0        1         1
5          FK_ContractorCompany Company ID           5            1        0         1
6          EmailAddress         Email Address        6            1        1         1
7          ServicesProvided     Services Provided    7            1        1         1
```

## Step 6: Test in UI

1. Navigate to the KWAT Contractor table view.
2. Verify that "Email Address" and "Services Provided" columns appear at the right end of the table.
3. Verify you can click in those cells to edit the values.
4. Verify the columns are sortable (click header to sort).
5. Verify the columns are filterable (if using a filter UI).

## Step 7: Rollback (if needed)

If the new columns don't look right or cause issues, disable them without deleting:

```sql
UPDATE dbo.APP_TABLE_COLUMNS
SET Visible = 0, Active = 0
WHERE TableID = 42 AND ColumnName IN ('EmailAddress', 'ServicesProvided');
```

Refresh the UI; the columns should disappear. To re-enable later:

```sql
UPDATE dbo.APP_TABLE_COLUMNS
SET Visible = 1, Active = 1
WHERE TableID = 42 AND ColumnName IN ('EmailAddress', 'ServicesProvided');
```

## Key Points

- **ColumnOrder controls left-to-right position** — columns display in order of ColumnOrder value.
- **Visible=1, Active=1** — both must be set to 1 for the column to appear in the UI.
- **Editable=1** — users can type into this field; if 0, it's read-only.
- **Sortable=1, Filterable=1** — users can sort/filter by this column in the UI.
- **MaxLength** — enforces input length in the database (and UI validation if implemented).
- **HelpText** — displayed as a tooltip when users hover over the column header or focus the field.
- **DataType='nvarchar'** — most text fields are nvarchar; other options include 'int', 'datetime', 'bit', 'dropdown', etc.

## Related Workflows

If you want to add a dropdown (status list) instead of a free-text field, see **Workflow 2: Add a Dropdown/Lookup List** in the main SKILL.md.

If you want to hide these columns from certain user roles, see **Workflow 3: Hide a Column from Specific Users**.
