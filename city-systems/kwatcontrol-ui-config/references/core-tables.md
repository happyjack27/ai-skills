# KWATControl Core Tables

Use this reference when the task requires identifying a KWATControl table or column before writing a query.

## APP_TABLES

Defines which tables are available for an application.

| Column | Type | Purpose |
|---|---|---|
| TableID | int | Primary key |
| ApplicationID | int | Foreign key to the application |
| TableName | nvarchar | Underlying data table |
| DisplayName | nvarchar | UI label |
| Description | nvarchar | Help text |
| Sortable | bit | Users can sort the table |
| Filterable | bit | Users can filter the table |
| AllowCreate | bit | Users can insert rows |
| AllowUpdate | bit | Users can edit rows |
| AllowDelete | bit | Users can delete rows |
| OrderBy | int | Menu order |
| Active | bit | Table is enabled |

## APP_TABLE_COLUMNS

Defines which columns appear, how they render, and their access behavior.

| Column | Type | Purpose |
|---|---|---|
| ColumnID | int | Primary key |
| TableID | int | Foreign key to APP_TABLES |
| ColumnName | nvarchar | Underlying database column |
| DisplayName | nvarchar | UI label |
| DataType | nvarchar | SQL or UI type such as `nvarchar`, `datetime`, or `dropdown` |
| ColumnOrder | int | Left-to-right display order |
| Visible | bit | Column is visible |
| Editable | bit | Column can be edited |
| Required | bit | Value is required before save |
| Sortable | bit | Column can be sorted |
| Filterable | bit | Column can be filtered |
| DropdownSource | nvarchar | APP_DROPDOWNS CATEGORY for dropdowns |
| MaxLength | int | Maximum text length |
| DefaultValue | nvarchar | New-row default |
| ValidationPattern | nvarchar | Regex or validation rule |
| HelpText | nvarchar | Tooltip or help text |
| Active | bit | Column is enabled |

## APP_DROPDOWNS

Lookup values grouped by category.

| Column | Type | Purpose |
|---|---|---|
| ID | int | Primary key |
| CATEGORY | nvarchar | Group name such as `ContractorStatus` |
| KEY | nvarchar | Internal value such as `ACTIVE` |
| VALUE | nvarchar | Display label such as `Active` |

## APP_GRANTS

Role-based table and column access.

| Column | Type | Purpose |
|---|---|---|
| GrantID | int | Primary key |
| RoleID | int | Role foreign key |
| TableID | int | Table foreign key |
| AllowRead | bit | Role can view |
| AllowCreate | bit | Role can insert |
| AllowUpdate | bit | Role can edit |
| AllowDelete | bit | Role can delete |
| ColumnID | int | Optional column-specific grant |

## APP_REPORTS and APP_REPORT_PARAMS

`APP_REPORTS` stores report identity, display metadata, SQL, and active state. `APP_REPORT_PARAMS`
stores each report parameter, including name, label, type, default, required flag, and optional
dropdown category.

## APP_SIDEBAR

Stores application navigation items: `ItemID`, `ApplicationID`, `MenuText`, `TargetTable`,
`DisplayOrder`, `ParentItemID`, `IconClass`, `RequiredRole`, and `Active`.

## Related Configuration Tables

The skill also covers `APP_ENHANCEMENTS`, `APP_ACCESS_FILTERS`, `APP_BADGES`, and `APP_CATEGORY`.
Confirm their current columns in the live KWATControl schema before writing DML; do not infer a
new table definition from this summary.
