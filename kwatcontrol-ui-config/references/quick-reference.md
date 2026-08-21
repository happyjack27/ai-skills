# KWATControl Quick Reference

## Database Location
- **Server:** sql-itmd
- **Database:** KWATControl

## Core Tables Cheat Sheet

| Table | Purpose | Key Columns |
|---|---|---|
| APP_APP_APP | Application registry | ApplicationID, AppName, AppDisplayName |
| APP_TABLES | Which tables appear in each app | TableID, ApplicationID, TableName, DisplayName |
| APP_TABLE_COLUMNS | Column config (labels, visibility, etc.) | ColumnID, TableID, ColumnName, DisplayName, DataType, Visible, Editable |
| APP_DROPDOWNS | Lookup/dropdown values | ID, CATEGORY, KEY, VALUE |
| APP_REPORTS | Report configurations | ReportID, ApplicationID, ReportName, DisplayName, ReportSQL |
| APP_REPORT_PARAMS | Report filters/parameters | ParamID, ReportID, ParamName, DataType |
| APP_SIDEBAR | Navigation menu items | ItemID, ApplicationID, MenuText, TargetTable, DisplayOrder |
| APP_GRANTS | Role-based access control | GrantID, RoleID, TableID, ColumnID, AllowRead, AllowCreate, AllowUpdate, AllowDelete |
| APP_ENHANCEMENTS | UI customizations | EnhancementID, TableID, ColumnID, CustomCSS, CustomJS |
| APP_ACCESS_FILTERS | Dynamic record-level access | FilterID, TableID, FilterSQL |
| APP_BADGES | Badge display settings | BadgeID, TableID, ColumnID, BadgeRule, BadgeStyle |
| APP_CATEGORY | Categorical grouping | CategoryID, CategoryName, DisplayOrder |

## Common Queries

### Get All Tables for an App
```sql
SELECT TableID, TableName, DisplayName, Active
FROM dbo.APP_TABLES
WHERE ApplicationID = (SELECT ApplicationID FROM dbo.APP_APP_APP WHERE AppName = 'KWAT')
ORDER BY DisplayName;
```

### Get All Columns for a Table
```sql
SELECT ColumnID, ColumnName, DisplayName, ColumnOrder, Visible, Editable, DataType, DropdownSource
FROM dbo.APP_TABLE_COLUMNS
WHERE TableID = @TableID
ORDER BY ColumnOrder;
```

### Get All Dropdowns in a Category
```sql
SELECT KEY, VALUE FROM dbo.APP_DROPDOWNS
WHERE CATEGORY = 'ContractorStatus'
ORDER BY KEY;
```

### Get Access Grants for a Role
```sql
SELECT t.TableName, c.ColumnName, g.AllowRead, g.AllowCreate, g.AllowUpdate, g.AllowDelete
FROM dbo.APP_GRANTS g
JOIN dbo.APP_TABLES t ON g.TableID = t.TableID
LEFT JOIN dbo.APP_TABLE_COLUMNS c ON g.ColumnID = c.ColumnID
WHERE g.RoleID = (SELECT RoleID FROM dbo.Roles WHERE RoleName = 'Admin')
ORDER BY t.TableName, c.ColumnName;
```

### List All Reports for an App
```sql
SELECT ReportID, ReportName, DisplayName, Active
FROM dbo.APP_REPORTS
WHERE ApplicationID = (SELECT ApplicationID FROM dbo.APP_APP_APP WHERE AppName = 'KWAT')
ORDER BY DisplayName;
```

### Get Sidebar Menu for an App
```sql
SELECT ItemID, MenuText, TargetTable, DisplayOrder, IconClass, Active
FROM dbo.APP_SIDEBAR
WHERE ApplicationID = (SELECT ApplicationID FROM dbo.APP_APP_APP WHERE AppName = 'KWAT')
ORDER BY DisplayOrder;
```

## Common Operations

### Add a Column to a Table
1. Get TableID: `SELECT TableID FROM dbo.APP_TABLES WHERE TableName = 'TableName';`
2. Get max ColumnOrder: `SELECT MAX(ColumnOrder) FROM dbo.APP_TABLE_COLUMNS WHERE TableID = @TableID;`
3. Insert: 
```sql
INSERT INTO dbo.APP_TABLE_COLUMNS (TableID, ColumnName, DisplayName, DataType, ColumnOrder, Visible, Editable, Active)
VALUES (@TableID, 'NewColumn', 'New Column', 'nvarchar', @MaxOrder+1, 1, 1, 1);
```

### Hide a Column
```sql
UPDATE dbo.APP_TABLE_COLUMNS SET Visible = 0 WHERE ColumnID = @ColumnID;
```

### Create a Dropdown
```sql
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
('MyCategory', 'KEY1', 'Display Value 1'),
('MyCategory', 'KEY2', 'Display Value 2');
```

### Link Dropdown to Column
```sql
UPDATE dbo.APP_TABLE_COLUMNS
SET DataType = 'dropdown', DropdownSource = 'MyCategory'
WHERE ColumnID = @ColumnID;
```

### Add a Report
```sql
INSERT INTO dbo.APP_REPORTS (ApplicationID, ReportName, DisplayName, ReportSQL, Active)
VALUES (@ApplicationID, 'ReportName', 'Report Display Name', 'SELECT ... FROM ...', 1);
```

### Add Sidebar Menu Item
```sql
INSERT INTO dbo.APP_SIDEBAR (ApplicationID, MenuText, TargetTable, DisplayOrder, IconClass, Active)
VALUES (@ApplicationID, 'Menu Text', 'TableName', 1, 'fa-icon', 1);
```

### Grant Access to a Role
```sql
INSERT INTO dbo.APP_GRANTS (RoleID, TableID, AllowRead, AllowCreate, AllowUpdate, AllowDelete)
VALUES (@RoleID, @TableID, 1, 1, 1, 1);
```

## Naming Conventions

- **ApplicationID & ApplicationName:** Use app's official name (KWAT, DPW_Citytime, HHMP)
- **CATEGORY (for dropdowns):** Use PascalCase, descriptive (ContractorStatus, ProjectPhase, YesNo)
- **KEY (dropdown internal value):** Use UPPERCASE_UNDERSCORE (ACTIVE, IN_PROGRESS, SUSPENDED)
- **VALUE (dropdown display label):** Use Title Case with spaces (Active, In Progress, Suspended)
- **TableName / ColumnName:** Match underlying database table/column names exactly
- **DisplayName:** Use Title Case with spaces for UI labels (Contractor ID, Project Name)
- **MenuText (sidebar):** Use clear, user-friendly terms (Contractors, Projects, Reports)

## Important Rules

1. **Always set Active=1** when adding new rows (unless intentionally disabled).
2. **Always set Visible=1** for columns you want users to see.
3. **Always verify changes in the UI** after modifying KWATControl.
4. **Never permanently DELETE** — use Active=0 or Visible=0 instead.
5. **ColumnOrder must be sequential** within a TableID (1, 2, 3, ... not 1, 3, 5).
6. **DisplayOrder must be sequential** within an ApplicationID for sidebars (1, 2, 3, ...).
7. **DropdownSource CATEGORY must exist** in APP_DROPDOWNS before linking a column.
8. **ApplicationID must exist** in APP_APP_APP before creating tables/reports/sidebars for it.

## Troubleshooting

| Problem | Diagnosis | Solution |
|---|---|---|
| Column not showing in UI | Visible=0 or Active=0 | `UPDATE ... SET Visible=1, Active=1 ...` |
| Dropdown shows no values | DropdownSource CATEGORY doesn't exist or is misspelled | Check `SELECT DISTINCT CATEGORY FROM APP_DROPDOWNS` |
| Wrong columns showing | ColumnOrder is not sequential or is negative | Fix ColumnOrder to be 1, 2, 3, ... |
| Sidebar menu not appearing | Active=0 or wrong ApplicationID | Check `SELECT * FROM APP_SIDEBAR WHERE ApplicationID = @AppID` |
| Report SQL fails | Invalid table/column names or wrong syntax | Test the ReportSQL in SQL Server first |
| Access denied for users | Grants not set or RoleID mismatch | Verify grants exist for user's RoleID |

## Data Types in APP_TABLE_COLUMNS

- **nvarchar** — text/string (most common)
- **int** — integer numbers
- **bigint** — large integers
- **decimal** — decimal numbers
- **datetime** — date and time
- **date** — date only
- **bit** — boolean (0=false, 1=true)
- **dropdown** — use with DropdownSource
- **custom** — app-specific rendering type

## Links & Related Skills

- **mssql-dynamic-tables** — for managing file attachment tables (ProjectFile, ContractorFile)
- **sql** — general SQL query help
- **java** — for understanding how web apps read KWATControl at runtime
