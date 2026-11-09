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

Live columns (verified in KWATControl): `ID` (identity, do not insert), `APP_NAME`, `MENU_PARENT`,
`DISPLAY_ORDER`, `LABEL`, `LABEL_STYLE`, `ICON`, `ICON_STYLE`, `URL`, `DIV`, `RELOAD`, `ACTION`,
`TABLE_NAME`. Older names such as `ItemID`, `ApplicationID`, `MenuText`, `ParentItemID`, and
`IconClass` do not exist.

**Hierarchy (three levels, enforced by KWATClient `Sidebar2.js`):**
- Top level: `MENU_PARENT` empty. Renders as a non-clickable heading (`<H3>`). Its `URL` is ignored.
- Second level: `MENU_PARENT` = the parent row's `LABEL` (a label, not an ID). Clickable when it has no children.
- Third level: `MENU_PARENT` = a second-level `LABEL`. Always clickable.

`CoreServices3.controlGetSidebar` attaches children to parents by `LABEL`, then orders by
`DISPLAY_ORDER ASC, MENU_PARENT, LABEL`. Negative `DISPLAY_ORDER` values sort first and are allowed.
A row whose `MENU_PARENT` matches no visible label is dropped. Access is filtered through
`APP_ACCESS_FILTERS` by `LABEL`. URLs beginning with `kwat/` are rewritten to KWATClient pagelets.

A clickable item must be a child of a heading. Never put a link in a top-level row.

## Related Configuration Tables

The skill also covers `APP_ENHANCEMENTS`, `APP_ACCESS_FILTERS`, `APP_BADGES`, and `APP_CATEGORY`.
Confirm their current columns in the live KWATControl schema before writing DML; do not infer a
new table definition from this summary.
