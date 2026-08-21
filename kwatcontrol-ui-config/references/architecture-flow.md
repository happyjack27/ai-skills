# KWATControl Architecture & Data Flow

## Complete System Stack

```
┌─────────────────────────────────────────────────────────────┐
│ BROWSER (KWATClient - TypeScript)                           │
│  - KWATClient/core/GlobalFunctions/attachWidgets()          │
│  - Instantiates widget classes for each <kwat-*> tag        │
│  - Reads data-* attributes (data-table, data-columns, etc.) │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ SERVICES SERVLET (KWATControlMSSQL)                         │
│  - HTTP endpoint: /Services?action=GetTableMetadata...      │
│  - Checks user permissions (access control)                 │
│  - Assembles metadata from KWATControl tables               │
│  - Caches response (improves performance)                   │
│  - Returns JSON: columns, dropdowns, column properties      │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ CORESERVICES3 (itmdutil Java class)                         │
│  - Extends itmdutil CoreServices                            │
│  - Calls SQUID-generated stored procedures                  │
│  - CRUD operations: InsertTable, SelectTable, etc.          │
│  - Data validation and transformation                       │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ SQUID PROCEDURES (Development.DynamicSQUID generated)       │
│  - InsertContractor, SelectContractor, etc.                 │
│  - Auto-generated from table schema                         │
│  - Includes new columns added via ALTER TABLE               │
└──────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────┐
│ KWATCONTROL DATABASE (sql-itmd)                             │
│  - APP_TABLES: table visibility, CRUD flags per app         │
│  - APP_TABLE_COLUMNS: column labels, visibility, types      │
│  - APP_DROPDOWNS: lookup values                             │
│  - APP_GRANTS: role-based permissions                       │
│  - APP_REPORTS, APP_SIDEBAR, APP_ENHANCEMENTS              │
└──────────────────────────────────────────────────────────────┘
```

## Page Load Sequence

### Step 1: Server Processes JSP

```
Client requests: GET /kwat/index.jsp?table=Contractor
Server:
  → Processes JSP template
  → Calls Services servlet for JavaScript libraries (KWATClient v1.x)
  → Calls Services servlet for CSS files
  → Injects data-* attributes into <kwat-table> tags:
      <kwat-table data-table="Contractor" data-app="KWAT" 
                  data-columns="ID,Label,EmailAddress,ServicesProvided" />
  → Returns HTML to browser
```

### Step 2: Browser Renders & Attaches Widgets

```
Browser:
  → Renders HTML (including <kwat-table> elements)
  → Calls KWATClient/core/GlobalFunctions/attachWidgets()
  → Finds all <kwat-*> elements on the page
  → For each element:
      → Creates widget instance (TableWidget, FormWidget, etc.)
      → Passes data-* attributes to widget constructor
      → Widget is attached to DOM element
```

### Step 3: Widget Fetches Metadata from Server

```
Widget (in browser memory):
  → Calls Services servlet: 
      /Services?action=GetTableMetadata&table=Contractor&app=KWAT&userId=kbaas
  → Request includes user credentials (for permission checking)
```

### Step 4: Services Servlet Assembles Metadata

```
Services Servlet (in KWATControlMSSQL):
  a) Check user permissions:
     → Query APP_GRANTS WHERE RoleID = user's role AND TableID = Contractor
     → Verify AllowRead = 1
     → Store: AllowCreate, AllowUpdate, AllowDelete for this user
  
  b) Build column metadata:
     → Query APP_TABLE_COLUMNS WHERE TableID = Contractor
     → For each column:
         → Get: ColumnName, DisplayName, ColumnOrder, Visible, Editable, 
                DataType, DropdownSource, MaxLength, HelpText
         → Check APP_GRANTS for column-level permissions
         → If DropdownSource set, fetch from APP_DROPDOWNS
     → Sort by ColumnOrder
  
  c) Cache the result (fast lookup next time)
  
  d) Return JSON:
     {
       "table": "Contractor",
       "columns": [
         { "name": "ID", "displayName": "ID", "order": 1, "visible": true, 
           "editable": false, "type": "int", "help": "..." },
         { "name": "Label", "displayName": "Contractor Name", "order": 2, 
           "visible": true, "editable": true, "type": "nvarchar", "help": "..." },
         { "name": "EmailAddress", "displayName": "Email Address", "order": 6,
           "visible": true, "editable": true, "type": "nvarchar", "help": "..." },
         { "name": "ServicesProvided", "displayName": "Services Provided", 
           "order": 7, "visible": true, "editable": true, "type": "nvarchar",
           "dropdownSource": "ContractorServices", "help": "..." }
       ],
       "dropdowns": {
         "ContractorServices": [
           { "key": "PLUMBING", "value": "Plumbing" },
           { "key": "HVAC", "value": "HVAC" },
           { "key": "LEAD_ABATE", "value": "Lead Abatement" }
         ]
       },
       "permissions": { "read": true, "create": true, "update": true, "delete": false }
     }
```

### Step 5: Widget Renders UI

```
Widget (in browser):
  → For each column returned:
      → If visible == true: render table column header
      → Create input field with type from metadata
      → If dropdown, render <select> with values from metadata
      → If editable == false, render as read-only text
      → Apply DataType validation (max length, date format, etc.)
  
  → Widget is now ready for user interaction
```

### Step 6: User Interacts (Edit/Save)

```
User: Clicks "Save" after editing Contractor record

Browser:
  → Widget validates against metadata rules (MaxLength, required, etc.)
  → Widget calls: CoreServices3.UpdateContractor(ID, newData)
  → CoreServices3 executes:
      EXEC [dbo].[UpdateContractorByPK] @ID=123, @Label='New Name', 
                                         @EmailAddress='email@...', ...
  → Database updated
  → Widget refreshes from database (calls SelectContractor)
  → UI re-renders with new values
```

## How KWATControl Changes Manifest in UI

### Scenario: Add a New Column to Contractor Table

**Database Level (sql-dev):**
```sql
-- Add physical column to table
ALTER TABLE [dbo].[Contractor] ADD ManagerName nvarchar(100) NULL;

-- Regenerate CRUD procedures
EXEC development.DynamicSQUID 
  @Schema='dbo', @Table='Contractor', @DoDrops=1;
-- Now UpdateContractorByPK includes ManagerName parameter
```

**UI Configuration Level (sql-itmd KWATControl):**
```sql
-- Add column to UI configuration
INSERT INTO dbo.APP_TABLE_COLUMNS 
  (TableID, ColumnName, DisplayName, DataType, ColumnOrder, Visible, Editable)
VALUES 
  (42, 'ManagerName', 'Manager Name', 'nvarchar', 8, 1, 1);
```

**User Sees (browser):**
1. **Next page load**, widget refreshes metadata (cache expires or user forces refresh)
2. Services servlet returns NEW metadata including ManagerName column
3. Widget renders new column header and input field
4. User can now edit ManagerName
5. Save → UpdateContractorByPK executes with ManagerName parameter
6. Data is saved to database

**Important:** User sees the new column on the **next page load**, not immediately. To see immediately:
- Hard refresh browser (Ctrl+Shift+R)
- Server cache may need to be invalidated (servlet restart in production)

### Scenario: Hide a Column for Specific Users

**KWATControl Configuration (sql-itmd):**
```sql
-- Option 1: Hide for everyone
UPDATE dbo.APP_TABLE_COLUMNS 
  SET Visible=0 
  WHERE TableID=42 AND ColumnName='SensitiveField';

-- Option 2: Hide for specific role only (row-level)
INSERT INTO dbo.APP_GRANTS 
  (RoleID, TableID, ColumnID, AllowRead)
VALUES 
  (3, 42, (SELECT ColumnID FROM APP_TABLE_COLUMNS WHERE ColumnName='SensitiveField'), 0);
```

**Result:**
- Admin users see the column (if AllowRead=1 in APP_GRANTS)
- Regular users don't see it (AllowRead=0 or missing grant)
- Users **without** access cannot edit the field (read-only or hidden)

### Scenario: Change Column Display Order

**KWATControl Configuration:**
```sql
-- Original: EmailAddress order=6, ServicesProvided order=7
-- Move EmailAddress after ServicesProvided (reverse order)

UPDATE dbo.APP_TABLE_COLUMNS 
  SET ColumnOrder=7.5 
  WHERE TableID=42 AND ColumnName='EmailAddress';

UPDATE dbo.APP_TABLE_COLUMNS 
  SET ColumnOrder=6 
  WHERE TableID=42 AND ColumnName='ServicesProvided';
```

**Result:**
- Columns render in ColumnOrder sequence (6, 7.5, ...)
- Next page load, ServicesProvided appears before EmailAddress

## Caching & Performance

### Where Metadata is Cached

1. **Services Servlet (server-side)**
   - Caches assembled metadata in memory
   - Key: table + app + role (approximate)
   - TTL: Configurable (often 15-60 minutes)
   - Invalidated on: servlet restart, manual cache clear

2. **Browser (client-side)**
   - Widget stores metadata in JavaScript memory
   - Persists across page navigation within same session
   - Cleared on: full page reload, session timeout

3. **CDN/Browser HTTP Cache**
   - Static CSS/JS files cached
   - Metadata JSON usually marked no-cache

### Cache Invalidation Gotchas

**Problem:** I added a new column to APP_TABLE_COLUMNS, but users still don't see it.

**Cause:** Server-side cache not invalidated.

**Solutions:**
1. Hard refresh browser (Ctrl+Shift+R)
2. Restart KWATControlMSSQL servlet (if admin)
3. Wait for cache TTL to expire
4. Add `&nocache=timestamp` to Services servlet URL (if supported)

## SQUID Procedures & Metadata Alignment

**Critical:** Physical table columns must match KWATControl APP_TABLE_COLUMNS entries.

### Workflow: Add New Contractor Column

**Step 1: Update Database Schema (sql-dev)**
```sql
ALTER TABLE dbo.Contractor ADD NewField nvarchar(50) NULL;
EXEC development.DynamicSQUID @Schema='dbo', @Table='Contractor', @DoDrops=1;
-- UpdateContractorByPK now accepts @NewField parameter
```

**Step 2: Update UI Configuration (sql-itmd KWATControl)**
```sql
INSERT INTO dbo.APP_TABLE_COLUMNS (...) VALUES (...NewField...);
```

**Step 3: Verify Alignment**
```sql
-- Check database column exists:
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME='Contractor' AND COLUMN_NAME='NewField';

-- Check UI config exists:
SELECT ColumnName, Visible, Editable 
FROM APP_TABLE_COLUMNS 
WHERE TableID=42 AND ColumnName='NewField';
```

**If misaligned:**
- Database has column, UI config missing → column exists in DB but not shown to users
- UI config has entry, database missing → widget tries to save to missing column → error

## Summary: What Changes Where

| Component | Location | What to Change | Effect on UI |
|---|---|---|---|
| Add column | sql-dev table + DynamicSQUID | ALTER TABLE, regenerate procs | Enables data storage |
| Show/hide column | sql-itmd APP_TABLE_COLUMNS | Visible=1/0 | Column appears/disappears |
| Change label | sql-itmd APP_TABLE_COLUMNS | DisplayName | Column header text updates |
| Restrict access | sql-itmd APP_GRANTS | AllowRead=0/1 | Column hidden from specific roles |
| Add dropdown | sql-itmd APP_DROPDOWNS | Insert category + values | Dropdown options available |
| Change permissions | sql-itmd APP_GRANTS | AllowCreate/Update/Delete | Save button enabled/disabled |
| Change column order | sql-itmd APP_TABLE_COLUMNS | ColumnOrder | Column position changes |

---

**See Also:**
- [quick-reference.md](quick-reference.md) — Query examples and common operations
- [add-contractor-columns.md](../examples/add-contractor-columns.md) — Worked example
- [dropdowns-and-lookups.md](../examples/dropdowns-and-lookups.md) — Dropdown configuration
- [mssql-dynamic-tables skill](../../mssql-dynamic-tables/SKILL.md) — How SQUID procedures are generated
