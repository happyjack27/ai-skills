---
name: kwatcontrol-ui-config
description: 'SQL Server KWATControl database: UI configuration and rendering control across all MSSQL-based web apps. Use for editing APP_TABLES, APP_TABLE_COLUMNS, APP_DROPDOWNS, APP_REPORTS, APP_SIDEBAR, APP_GRANTS, APP_ENHANCEMENTS, and other UI control tables to manage how the web UI renders tables, fields, reports, permissions, and navigation for all applications (KWAT, DPW, HHMP, etc.). Includes patterns for adding/removing fields, configuring dropdowns, managing access, and updating sidebar navigation.'
---

# KWATControl Database — UI Configuration & Rendering

## Purpose

Help an AI edit and manage the KWATControl database tables that define how all MSSQL-based web applications (KWAT, DPW apps, HHMP, etc.) render tables, columns, reports, dropdowns, navigation, and access controls in the UI.

## Scope

**Included:**
- APP_TABLES — which tables are available for a given application/module
- APP_TABLE_COLUMNS — field names, display labels, data types, visibility, editability, sorting, filtering
- APP_DROPDOWNS — lookup/dropdown lists (CATEGORY, KEY, VALUE structure)
- APP_REPORTS — report configurations and parameters
- APP_SIDEBAR — sidebar navigation menu structure
- APP_GRANTS — role-based access control (who can see/edit what)
- APP_ENHANCEMENTS — UI customizations and special rendering
- APP_ACCESS_FILTERS — dynamic access filtering (e.g., filter records by logged-in user)
- APP_BADGES — badge display and styling
- APP_CATEGORY — categorical grouping for UI organization

**Out of scope:**
- Business logic or data validation (handled in application code)
- Database schema creation (KWATControl is a pre-existing configuration DB)
- Application source code changes (only database config)

## When to Use

- User needs to add/remove a column from a web app UI table view
- User needs to configure a dropdown or lookup list
- User needs to hide/show a field or table for specific users/roles
- User needs to add a new report or modify report parameters
- User needs to change field labels, sorting, or filter behavior
- User needs to update sidebar navigation menu items
- User needs to configure access grants (who can view/edit which data)
- User needs to apply UI enhancements (styling, custom rendering)
- User wants to understand how database changes flow through KWATClient → Services servlet → KWATControl (see [architecture-flow.md](./references/architecture-flow.md))

## Inputs Expected

| Input | Description | Example |
|---|---|---|
| Application | Which app to configure (KWAT, DPW_Citytime, HHMP, etc.) | KWAT, DPW_AppAdmin |
| Table | Which table to configure (if applicable) | Project, Contractor, WorkOrder |
| Operation | Add column, hide field, add dropdown, configure grant, add report, etc. | "add Column to Project table", "hide DateQualified from Contractor" |
| Details | Specific settings (labels, data types, visibility, access roles) | Label="Owner Name", DataType="nvarchar", Visible=1, EditableByRoles="Admin,Manager" |

## Outputs Produced

| Output | Format | Description |
|---|---|---|
| UPDATE/INSERT statements | SQL code block | DML to modify KWATControl tables |
| Verification queries | SQL SELECT code block | Queries to verify the change took effect |
| Before/after summary | Text + SQL | What changed and why |

## Ground Truth References

When you need deeper implementation details beyond what this skill provides, consult these source-of-truth projects:

| Project | Location | Purpose | When to Reference |
|---|---|---|---|
| **KWATDocumentation** | `KWATDocumentation/` | Architecture diagrams, UML, load order, conventions, row-level security, reports, templates | Understanding full system design, conventions, advanced features (RLS, record bundling, etc.) |
| **KWATClient** | `KWATClient/src/`, `KWATClient/WebContent/` | TypeScript/JavaScript widget code, how metadata is consumed on frontend, data-* attribute binding | Troubleshooting UI rendering issues, understanding widget lifecycle, custom styling/behavior |
| **KWATControlMSSQL** | `KWATControlMSSQL/src/`, `KWATControlMSSQL/WebContent/` | Services servlet code, how metadata is assembled and cached, permission filtering logic | Understanding metadata flow, cache behavior, access control implementation |
| **itmdutil** | `itmdutil/src/` | CoreServices3 backend class (extends CoreServices), SQUID procedure calling patterns | Understanding data persistence, CRUD operation flow, error handling |
| **mssql-dynamic-tables skill** | `ai-skills/mssql-dynamic-tables/` | SQUID procedure generation, dynamic schema patterns, naming conventions | When adding new columns and regenerating CRUD procedures |

**Example:** If you need to understand how the Services servlet determines whether a user can access a column, look at `KWATControlMSSQL/src/.../Services.java` to see the actual permission-checking code. This skill documents *what* to change in KWATControl, but the servlet code shows *how* it's actually enforced.

## Core Tables

### APP_TABLES
Defines which tables are available in each application.

| Column | Type | Purpose |
|---|---|---|
| TableID | int | Primary key |
| ApplicationID | int | Foreign key to APP_APP_APP (which application) |
| TableName | nvarchar | Name of the underlying data table (e.g., "Project") |
| DisplayName | nvarchar | UI label (e.g., "Projects") |
| Description | nvarchar | Help text or description |
| Sortable | bit | Can users sort this table? |
| Filterable | bit | Can users filter this table? |
| AllowCreate | bit | Can users insert new rows? |
| AllowUpdate | bit | Can users edit rows? |
| AllowDelete | bit | Can users delete rows? |
| OrderBy | int | Display order in menu |
| Active | bit | Is this table enabled? |

### APP_TABLE_COLUMNS
Defines which columns appear for each table, how they render, and access control.

| Column | Type | Purpose |
|---|---|---|
| ColumnID | int | Primary key |
| TableID | int | Foreign key to APP_TABLES |
| ColumnName | nvarchar | Name of the underlying database column |
| DisplayName | nvarchar | UI label (e.g., "Project Name") |
| DataType | nvarchar | SQL type or UI control type (e.g., "nvarchar", "int", "datetime", "dropdown") |
| ColumnOrder | int | Left-to-right display order |
| Visible | bit | Is this column visible in the UI? |
| Editable | bit | Can users edit this field? (read-only if 0) |
| Required | bit | Must this field be filled before saving? |
| Sortable | bit | Can users sort by this column? |
| Filterable | bit | Can users filter by this column? |
| DropdownSource | nvarchar | For dropdowns: reference to APP_DROPDOWNS CATEGORY |
| MaxLength | int | Maximum input length (for text fields) |
| DefaultValue | nvarchar | Pre-filled value for new rows |
| ValidationPattern | nvarchar | Regex or validation rule |
| HelpText | nvarchar | Tooltip or help message |
| Active | bit | Is this column enabled? |

### APP_DROPDOWNS
Lookup and dropdown values.

| Column | Type | Purpose |
|---|---|---|
| ID | int | Primary key |
| CATEGORY | nvarchar | Grouping name (e.g., "ContractorType", "ProjectStatus") |
| KEY | nvarchar | Internal identifier (e.g., "ACTIVE", "INACTIVE") |
| VALUE | nvarchar | Display label (e.g., "Active", "Inactive") |

### APP_GRANTS
Role-based access control: who can see/edit which tables and columns.

| Column | Type | Purpose |
|---|---|---|
| GrantID | int | Primary key |
| RoleID | int | Foreign key to role (e.g., Admin, Manager, User) |
| TableID | int | Foreign key to APP_TABLES |
| AllowRead | bit | Can this role view the table? |
| AllowCreate | bit | Can this role insert rows? |
| AllowUpdate | bit | Can this role edit rows? |
| AllowDelete | bit | Can this role delete rows? |
| ColumnID | int | (Optional) If set, grant applies to specific column only |

### APP_REPORTS
Report configurations.

| Column | Type | Purpose |
|---|---|---|
| ReportID | int | Primary key |
| ApplicationID | int | Foreign key to APP_APP_APP |
| ReportName | nvarchar | Internal name (e.g., "ProjectSummary") |
| DisplayName | nvarchar | UI label (e.g., "Project Summary Report") |
| Description | nvarchar | Report purpose |
| ReportSQL | nvarchar(max) | SQL query that generates the report |
| Active | bit | Is this report enabled? |

### APP_REPORT_PARAMS
Report parameters and filters.

| Column | Type | Purpose |
|---|---|---|
| ParamID | int | Primary key |
| ReportID | int | Foreign key to APP_REPORTS |
| ParamName | nvarchar | SQL parameter name (e.g., "@StartDate") |
| DisplayName | nvarchar | UI label (e.g., "Start Date") |
| DataType | nvarchar | nvarchar, int, datetime, bit, etc. |
| DefaultValue | nvarchar | Pre-filled value |
| Required | bit | Must user supply this parameter? |
| DropdownSource | nvarchar | If lookup, reference to APP_DROPDOWNS CATEGORY |

### APP_SIDEBAR
Sidebar/navigation menu structure.

| Column | Type | Purpose |
|---|---|---|
| ItemID | int | Primary key |
| ApplicationID | int | Foreign key to APP_APP_APP |
| MenuText | nvarchar | Link text displayed in sidebar |
| TargetTable | nvarchar | Underlying table name or URL |
| DisplayOrder | int | Top-to-bottom order |
| ParentItemID | int | If set, this is a submenu (hierarchical) |
| IconClass | nvarchar | CSS class for icon (FontAwesome, etc.) |
| RequiredRole | nvarchar | Only show to users with this role |
| Active | bit | Is this menu item enabled? |

## Common Workflows

### Workflow 1: Add a Column to an Existing Table in the UI

**Goal:** Show a new database column in a table view (e.g., add "EmailAddress" to the Contractor table in the KWAT app).

**Steps:**

1. **Get the TableID for the table:**
   ```sql
   USE KWATControl;
   SELECT TableID, TableName, DisplayName FROM dbo.APP_TABLES 
   WHERE ApplicationID = (SELECT ApplicationID FROM dbo.APP_APP_APP WHERE AppName = 'KWAT')
     AND TableName = 'Contractor';
   ```

2. **Get the current max ColumnOrder:**
   ```sql
   SELECT MAX(ColumnOrder) AS MaxOrder FROM dbo.APP_TABLE_COLUMNS 
   WHERE TableID = @TableID;
   ```

3. **Insert the new column:**
   ```sql
   INSERT INTO dbo.APP_TABLE_COLUMNS (
     TableID, ColumnName, DisplayName, DataType, ColumnOrder,
     Visible, Editable, Required, Sortable, Filterable, Active
   ) VALUES (
     @TableID, 'EmailAddress', 'Email Address', 'nvarchar',
     @MaxOrder + 1, 1, 1, 0, 1, 1, 1
   );
   ```

4. **Verify:**
   ```sql
   SELECT ColumnID, ColumnName, DisplayName, ColumnOrder, Visible
   FROM dbo.APP_TABLE_COLUMNS
   WHERE TableID = @TableID
   ORDER BY ColumnOrder;
   ```

### Workflow 2: Add a Dropdown/Lookup List

**Goal:** Create a new dropdown for field values (e.g., "ContractorStatus" with values Active, Inactive, Suspended).

**Steps:**

1. **Insert the dropdown category and values:**
   ```sql
   INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
   ('ContractorStatus', 'ACTIVE', 'Active'),
   ('ContractorStatus', 'INACTIVE', 'Inactive'),
   ('ContractorStatus', 'SUSPENDED', 'Suspended');
   ```

2. **Link the dropdown to a column:**
   ```sql
   UPDATE dbo.APP_TABLE_COLUMNS
   SET DataType = 'dropdown', DropdownSource = 'ContractorStatus'
   WHERE TableID = @TableID AND ColumnName = 'Status';
   ```

3. **Verify:**
   ```sql
   SELECT CATEGORY, KEY, VALUE FROM dbo.APP_DROPDOWNS 
   WHERE CATEGORY = 'ContractorStatus'
   ORDER BY KEY;
   ```

### Workflow 3: Hide a Column from Specific Users

**Goal:** Hide "DateQualified" column from regular users, but show to Admins.

**Steps:**

1. **Get the ColumnID:**
   ```sql
   SELECT ColumnID FROM dbo.APP_TABLE_COLUMNS 
   WHERE TableID = @TableID AND ColumnName = 'DateQualified';
   ```

2. **Create a grant for Admins only:**
   ```sql
   INSERT INTO dbo.APP_GRANTS (RoleID, TableID, ColumnID, AllowRead, AllowCreate, AllowUpdate)
   SELECT (SELECT RoleID FROM dbo.Roles WHERE RoleName = 'Admin'),
          @TableID, @ColumnID, 1, 1, 1;
   
   -- Deny for regular users:
   INSERT INTO dbo.APP_GRANTS (RoleID, TableID, ColumnID, AllowRead, AllowCreate, AllowUpdate)
   SELECT (SELECT RoleID FROM dbo.Roles WHERE RoleName = 'User'),
          @TableID, @ColumnID, 0, 0, 0;
   ```

3. **Alternatively, hide globally for now:**
   ```sql
   UPDATE dbo.APP_TABLE_COLUMNS
   SET Visible = 0
   WHERE ColumnID = @ColumnID;
   ```

### Workflow 4: Add a New Report

**Goal:** Create a "Project Cost Summary" report.

**Steps:**

1. **Insert the report:**
   ```sql
   INSERT INTO dbo.APP_REPORTS (
     ApplicationID, ReportName, DisplayName, Description, ReportSQL, Active
   ) VALUES (
     @ApplicationID, 'ProjectCostSummary', 'Project Cost Summary',
     'Summary of project costs by contractor',
     'SELECT ProjectID, ProjectName, SUM(Cost) AS TotalCost FROM vw_ProjectCosts GROUP BY ProjectID, ProjectName',
     1
   );
   ```

2. **Add report parameters (if needed):**
   ```sql
   INSERT INTO dbo.APP_REPORT_PARAMS (
     ReportID, ParamName, DisplayName, DataType, Required
   ) VALUES (
     @ReportID, '@StartDate', 'Start Date', 'datetime', 1
   );
   ```

3. **Verify:**
   ```sql
   SELECT ReportID, ReportName, DisplayName FROM dbo.APP_REPORTS 
   WHERE ApplicationID = @ApplicationID;
   ```

### Workflow 5: Update Sidebar Navigation

**Goal:** Add a "Contractor Management" menu item to the sidebar.

**Steps:**

1. **Get the ApplicationID:**
   ```sql
   SELECT ApplicationID FROM dbo.APP_APP_APP WHERE AppName = 'KWAT';
   ```

2. **Insert the sidebar item:**
   ```sql
   INSERT INTO dbo.APP_SIDEBAR (
     ApplicationID, MenuText, TargetTable, DisplayOrder, IconClass, Active
   ) VALUES (
     @ApplicationID, 'Contractors', 'Contractor', 3, 'fa-users', 1
   );
   ```

3. **Verify:**
   ```sql
   SELECT ItemID, MenuText, TargetTable, DisplayOrder FROM dbo.APP_SIDEBAR
   WHERE ApplicationID = @ApplicationID
   ORDER BY DisplayOrder;
   ```

### Workflow 6: Configure Form Layout and Component Sizing

**Goal:** Create a well-organized form layout with proper card grouping, column widths, and visual structure.

**Key Concepts:**

- **COLUMN_GROUP** — Card/section name (e.g., "Contact Info", "Services"). Group related fields together logically. Avoid redundant groupings (e.g., don't have both "General" and "Basic Info" cards).
- **COMPONENT_SIZE** — Component/input width. Common values: 36 (medium), 100 (full-width textarea). Controls the actual size of the input element on the form.
- **ROW_12THS** — Grid width in a 12-column layout. Values: 6 (half-width, two fields per row), 12 (full-width, one field per row). Controls how much space the field takes horizontally.
- **LINE_BREAK** — Whether this field starts on a NEW line (1=yes, default) or appears on the SAME line as the previous field (0=no). Use LINE_BREAK=0 only when you want side-by-side fields (e.g., PhoneNumber and Email both ROW_12THS=6).
- **HUMAN_NAME** — Display label. Set to NULL to auto-generate from column name by inserting spaces between CamelCase boundaries (e.g., "ContactName" → "Contact Name"). This reduces duplication and keeps labels in sync.

**Steps:**

1. **Plan the form layout** — Sketch out which fields go in which cards, and which should be side-by-side.

   Example:
   ```
   [Contact Info]
     ContactName (full-width)
     OwnerName (full-width)
     PhoneNumber (half-width) | EmailAddress (half-width) [same line]
     Address (full-width)
   
   [Services]
     ServicesProvided (full-width textarea)
     DateQualified (full-width date)
   ```

2. **Set COLUMN_GROUP, COMPONENT_SIZE, ROW_12THS, and LINE_BREAK:**

   ```sql
   UPDATE dbo.APP_TABLE_COLUMNS
   SET 
     COLUMN_GROUP = 'Contact Info',
     COMPONENT_SIZE = 36,
     ROW_12THS = 12,
     LINE_BREAK = 1
   WHERE APP_NAME = 'MilwaukeeHealthyHomeProgram' 
     AND TABLE_NAME = 'Contractor' 
     AND COLUMN_NAME = 'ContactName';
   
   UPDATE dbo.APP_TABLE_COLUMNS
   SET 
     COLUMN_GROUP = 'Contact Info',
     COMPONENT_SIZE = 36,
     ROW_12THS = 6,
     LINE_BREAK = 1
   WHERE APP_NAME = 'MilwaukeeHealthyHomeProgram' 
     AND TABLE_NAME = 'Contractor' 
     AND COLUMN_NAME = 'PhoneNumber';
   
   UPDATE dbo.APP_TABLE_COLUMNS
   SET 
     COLUMN_GROUP = 'Contact Info',
     COMPONENT_SIZE = 36,
     ROW_12THS = 6,
     LINE_BREAK = 0  -- Same line as PhoneNumber
   WHERE APP_NAME = 'MilwaukeeHealthyHomeProgram' 
     AND TABLE_NAME = 'Contractor' 
     AND COLUMN_NAME = 'EmailAddress';
   
   UPDATE dbo.APP_TABLE_COLUMNS
   SET 
     COLUMN_GROUP = 'Services',
     COMPONENT_SIZE = 100,
     ROW_12THS = 12,
     LINE_BREAK = 1
   WHERE APP_NAME = 'MilwaukeeHealthyHomeProgram' 
     AND TABLE_NAME = 'Contractor' 
     AND COLUMN_NAME = 'ServicesProvided';
   ```

3. **Verify the layout:**
   ```sql
   SELECT 
     DISPLAY_ORDER,
     COLUMN_NAME,
     COLUMN_GROUP,
     COMPONENT_SIZE,
     ROW_12THS,
     LINE_BREAK
   FROM dbo.APP_TABLE_COLUMNS
   WHERE APP_NAME = 'MilwaukeeHealthyHomeProgram' 
     AND TABLE_NAME = 'Contractor'
   ORDER BY DISPLAY_ORDER;
   ```

**Tips:**

- Use descriptive COLUMN_GROUP names that reflect the data category (e.g., "Contact Info", "Services", "Billing", not "General" or "Basic Info").
- Avoid nesting redundant card names (e.g., "Basic Info" inside "General" — pick one).
- For side-by-side fields, ensure both have ROW_12THS=6 and only the *second* field has LINE_BREAK=0.
- COMPONENT_SIZE=100 is good for `textarea` fields (ServicesProvided); COMPONENT_SIZE=36 works for most textfield/email/phone/date fields.
- Always set HUMAN_NAME=NULL to let the system auto-generate friendly labels from CamelCase column names.

## Quality Standards

- **Never DELETE from KWATControl without backup** — always SET Active=0 first to disable, then verify the change in UI before permanently deleting.
- **Always update DisplayName alongside ColumnName** — UI reflects DisplayName, so keep them in sync.
- **Verify after every change** — query the modified table to confirm the values were inserted/updated correctly.
- **Test in non-production first** — if possible, apply changes to a dev KWATControl database before production.
- **Document why you changed it** — add a comment in the query or a note in the ticket explaining the business reason.
- **Check for dependent dropdowns** — if you change a DropdownSource, verify all UI fields using that dropdown still work.
- **Choose data types intelligently** — Use domain-specific types (email, phone, address google, date, textarea) instead of generic textfield when the field content has semantic meaning. This enables proper validation, formatting, and user experience (e.g., "email" type triggers email validation; "phone" type formats numbers; "address google" integrates with Google Maps).
- **Set HUMAN_NAME to NULL** — Let the system auto-generate display labels from CamelCase column names (e.g., EmailAddress → "Email Address"). This prevents label duplication and keeps labels in sync with column names.
- **For file attachment tables, set FK_ID DATA_TYPE to 'attachments'** — Not "textfield". Configure FK_TABLE, FK_KEY, FK_VALUE to point to the parent table (e.g., FK_TABLE='Project', FK_KEY='ID', FK_VALUE='ID').

## Common Mistakes

- **Wrong ApplicationID** — querying APP_TABLES without filtering by ApplicationID returns all apps' tables.
- **Forgetting Active=0** — adding a column with Active=0 means it won't show in the UI.
- **Typos in DropdownSource** — if DropdownSource='ContractorStatuss' (with extra 's'), the UI won't find matching APP_DROPDOWNS entries.
- **Missing ColumnOrder** — if you insert a column without setting ColumnOrder, it may sort last or conflict with others.
- **Not updating DisplayName** — if ColumnName='DateQualified' but DisplayName is blank, the UI shows a blank header.
- **Deleting instead of disabling** — permanently deleting a row means no audit trail; SET Active=0 is safer.
- **Redundant COLUMN_GROUP names** — Don't create both "General" and "Basic Info" cards; consolidate into one meaningful name.
- **Using generic textfield for semantic data** — Use "email" DATA_TYPE for email addresses, "phone" for phone numbers, "address google" for addresses, "textarea" for multi-line text, "date" for dates. This enables proper validation and better UX.
- **Getting LINE_BREAK backwards** — LINE_BREAK=1 means "start on a NEW line" (default), LINE_BREAK=0 means "same line as previous field". Most fields should have LINE_BREAK=1. Only set to 0 for fields you want side-by-side.
- **Wrong FK_ID data type** — For file attachment tables, set FK_ID DATA_TYPE to 'attachments', not 'textfield'. And configure FK_TABLE, FK_KEY, FK_VALUE to reference the parent table.
- **Hardcoding HUMAN_NAME** — Avoid redundant labels like "Owner Name" when the column is already named "OwnerName". Set HUMAN_NAME=NULL and let the system auto-generate friendly labels.

## Validation Checklist

- [ ] Correct ApplicationID identified
- [ ] Correct TableID or ColumnID retrieved
- [ ] INSERT/UPDATE syntax verified (no typos)
- [ ] Active bit set to 1 (if you want the change visible)
- [ ] ColumnOrder or DisplayOrder is sequential and sensible
- [ ] DropdownSource (if used) matches an existing CATEGORY in APP_DROPDOWNS
- [ ] Required field defaults are sensible (not forcing users into dead ends)
- [ ] Grants/permissions are correct (not locking out all users)
- [ ] Verification query runs and shows the expected rows
- [ ] UI test: navigate to the modified table/report/menu and confirm the change appears

## Examples

See `examples/`.

## References

- **KWATControl database** — Located on sql-itmd server; shared configuration DB for all MSSQL-based web apps.
- **APP_* tables** — All UI configuration tables start with APP_ prefix.
- **Lookup pattern** — Most tables have (ApplicationID, TableID) or (ApplicationID, ReportID) foreign keys; always filter by ApplicationID to avoid cross-app pollution.

## Related Skills

- [`../sql/SKILL.md`](../sql/SKILL.md) — General SQL query/DML work.
- [`../java/SKILL.md`](../java/SKILL.md) — Application code that reads KWATControl at runtime.
