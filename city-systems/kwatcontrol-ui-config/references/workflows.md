# KWATControl Workflows

Read only the workflow matching the requested operation. Query the target application and table
first; never assume IDs from another application.

## Add a Column

1. Find `TableID` by filtering `APP_TABLES` on `ApplicationID` and `TableName`.
2. Read `MAX(ColumnOrder)` for that table.
3. Insert the column into `APP_TABLE_COLUMNS` with an explicit `ColumnOrder`, `Visible`,
   `Editable`, `Required`, `Sortable`, `Filterable`, and `Active` value.
4. Verify the inserted row and test the UI. If the physical column is new, handle the physical
   schema and CRUD procedure change separately before changing KWATControl.

```sql
SELECT TableID, TableName, DisplayName
FROM dbo.APP_TABLES
WHERE ApplicationID = @ApplicationID AND TableName = @TableName;

SELECT MAX(ColumnOrder) AS MaxOrder
FROM dbo.APP_TABLE_COLUMNS
WHERE TableID = @TableID;

INSERT INTO dbo.APP_TABLE_COLUMNS
    (TableID, ColumnName, DisplayName, DataType, ColumnOrder,
     Visible, Editable, Required, Sortable, Filterable, Active)
VALUES
    (@TableID, @ColumnName, @DisplayName, @DataType, @MaxOrder + 1,
     1, 1, 0, 1, 1, 1);
```

## Add a Dropdown

1. Insert the category and values into `APP_DROPDOWNS`.
2. Set the target column's `DataType` to `dropdown` and `DropdownSource` to the exact category.
3. Verify both the category rows and the column configuration.

```sql
INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
    ('ContractorStatus', 'ACTIVE', 'Active'),
    ('ContractorStatus', 'INACTIVE', 'Inactive'),
    ('ContractorStatus', 'SUSPENDED', 'Suspended');

UPDATE dbo.APP_TABLE_COLUMNS
SET DataType = 'dropdown', DropdownSource = 'ContractorStatus'
WHERE TableID = @TableID AND ColumnName = 'Status';
```

## Restrict a Column by Role

1. Resolve the target `ColumnID` and role IDs.
2. Insert explicit grants for the allowed and denied roles.
3. Verify the effective permission and test with representative users.
4. To hide a field globally, set `Visible = 0`; do not create unnecessary role grants.

## Add a Report

1. Insert the report into `APP_REPORTS` with the correct `ApplicationID` and explicit `Active` value.
2. Insert required parameters into `APP_REPORT_PARAMS`.
3. Validate the report SQL independently, then verify the report row and parameter rows.

```sql
INSERT INTO dbo.APP_REPORTS
    (ApplicationID, ReportName, DisplayName, Description, ReportSQL, Active)
VALUES
    (@ApplicationID, @ReportName, @DisplayName, @Description, @ReportSQL, 1);

INSERT INTO dbo.APP_REPORT_PARAMS
    (ReportID, ParamName, DisplayName, DataType, Required)
VALUES
    (@ReportID, '@StartDate', 'Start Date', 'datetime', 1);
```

## Update Sidebar Navigation

1. Resolve the application ID.
2. Choose a non-conflicting `DisplayOrder` and set `ParentItemID` when adding a submenu.
3. Insert the item with its target table or URL, icon, role, and active state.
4. Query the complete application menu ordered by `DisplayOrder` and test navigation.

## Configure Form Layout

Use `COLUMN_GROUP` for meaningful cards, `ROW_12THS` for the 12-column grid,
`COMPONENT_SIZE` for input width, and `LINE_BREAK` to control row starts. For side-by-side fields,
use `ROW_12THS = 6` on both fields and `LINE_BREAK = 0` only on the second field. Use
`COMPONENT_SIZE = 100` for large text areas and `36` for ordinary text, email, phone, and date fields.
Set `HUMAN_NAME = NULL` when the system should derive a label from CamelCase.

Verify the resulting layout ordered by display order and test the actual form; metadata caches may
require a browser hard refresh or servlet restart.

## Standard Verification

After every change:

- Re-query the changed rows using the correct application/table/report ID.
- Confirm `Active` and visibility values match the intended behavior.
- Check dropdown categories, grants, and dependent configuration for consistency.
- Test the affected UI with representative permissions.
