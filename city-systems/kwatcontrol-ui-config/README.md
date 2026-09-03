# Getting Started with KWATControl Configuration

## The Big Picture

**KWATControl** is a database on `sql-itmd` that controls how all MSSQL-based web apps (KWAT, DPW, HHMP) render their UIs.

**You edit KWATControl tables** → **Users see changes in the web app UI** (with caching delays)

## What's Your Task?

### Scenario 1: "I need to add a new field to a table's UI"

**Example:** Add an "Owner Name" column to the Contractor table.

**Steps:**
1. Add physical column to database (sql-dev):
   ```sql
   ALTER TABLE [dbo].[Contractor] ADD OwnerName nvarchar(100) NULL;
   ```
2. Regenerate CRUD procedures:
   ```sql
   EXEC development.DynamicSQUID @Schema='dbo', @Table='Contractor', @DoDrops=1;
   ```
3. Configure UI to show it (sql-itmd KWATControl):
   ```sql
   INSERT INTO dbo.APP_TABLE_COLUMNS (TableID, ColumnName, DisplayName, DataType, ColumnOrder, Visible, Editable, Active)
   VALUES (42, 'OwnerName', 'Owner Name', 'nvarchar', 6, 1, 1, 1);
   ```
4. Hard refresh browser (Ctrl+Shift+R) to see it.

**See:** [add-contractor-columns.md](../examples/add-contractor-columns.md)

---

### Scenario 2: "I need to create a dropdown list"

**Example:** Add a "Status" dropdown with values: Active, Inactive, Suspended.

**Steps:**
1. Create dropdown in KWATControl:
   ```sql
   INSERT INTO dbo.APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES
   ('ContractorStatus', 'ACTIVE', 'Active'),
   ('ContractorStatus', 'INACTIVE', 'Inactive'),
   ('ContractorStatus', 'SUSPENDED', 'Suspended');
   ```
2. Link to a column:
   ```sql
   UPDATE dbo.APP_TABLE_COLUMNS 
   SET DataType='dropdown', DropdownSource='ContractorStatus'
   WHERE ColumnID=123;
   ```
3. Hard refresh browser to see dropdown values.

**See:** [dropdowns-and-lookups.md](../examples/dropdowns-and-lookups.md)

---

### Scenario 3: "Users shouldn't see a certain field"

**Example:** Hide "SensitiveField" from everyone (or specific roles).

**Option A: Hide from everyone**
```sql
UPDATE dbo.APP_TABLE_COLUMNS 
SET Visible=0 
WHERE TableID=42 AND ColumnName='SensitiveField';
```

**Option B: Hide from specific role only**
```sql
INSERT INTO dbo.APP_GRANTS (RoleID, TableID, ColumnID, AllowRead)
VALUES (3, 42, 123, 0);  -- Role 3 cannot read column 123
```

**Result:** Users hard-refresh and field disappears.

---

### Scenario 4: "I changed KWATControl but users don't see it"

**Most common issue:** Browser or server cached the old metadata.

**Steps to diagnose:**
1. Verify change is in database:
   ```sql
   SELECT DisplayName FROM APP_TABLE_COLUMNS WHERE ColumnID=123;
   ```
2. Tell users to hard-refresh: **Ctrl+Shift+R** (Windows) or **Cmd+Shift+R** (Mac)
3. If still not working after hard-refresh, request admin to restart the servlet.

**See:** [cache-invalidation.md](../references/cache-invalidation.md)

---

## Files in This Skill

| File | Purpose | Read First? |
|---|---|---|
| **SKILL.md** | Overview, scope, table descriptions | ✓ Yes |
| **examples/add-contractor-columns.md** | Step-by-step: add a column | ✓ Yes (if adding columns) |
| **examples/dropdowns-and-lookups.md** | Step-by-step: create dropdowns | ✓ Yes (if creating dropdowns) |
| **references/quick-reference.md** | SQL query cheat sheet | When you need fast SQL examples |
| **references/architecture-flow.md** | Full system diagram & data flow | When you want to understand the whole system |
| **references/cache-invalidation.md** | Troubleshooting cache issues | When changes aren't showing up |
| **README.md** (this file) | Getting started guide | ✓ You're reading it! |

---

## Ground Truth Source Projects

This skill documents what to change in KWATControl, but if you need deeper understanding of *how* things work, check the actual source code:

| Project | What It Contains | When to Look |
|---|---|---|
| **KWATDocumentation** | Conventions, load order, UML diagrams, advanced features (RLS, record bundles, templates) | Understanding system design or advanced features |
| **KWATClient** | Frontend TypeScript/JavaScript code that reads metadata and renders widgets | UI rendering issues, widget lifecycle, custom styling |
| **KWATControlMSSQL** | Services servlet that assembles metadata and applies access control | Metadata flow, caching, permission checking |
| **itmdutil/CoreServices3** | Backend class that calls SQUID procedures to persist data | Data flow, CRUD operations, error handling |

---

## Key Concepts

### 1. TableID

Each table in each application has a unique TableID in KWATControl.

**To find a table's ID:**
```sql
SELECT TableID, TableName, DisplayName 
FROM APP_TABLES 
WHERE TableName='Contractor';
```

**Result:** TableID = 42

Use this ID when:
- Adding columns to APP_TABLE_COLUMNS
- Setting up access grants
- Querying any table-specific configuration

---

### 2. ColumnOrder

Determines left-to-right position in the UI table view. Must be sequential (no gaps).

**Example:**
```
ColumnOrder=1 → ID (leftmost)
ColumnOrder=2 → Label
ColumnOrder=3 → Active
ColumnOrder=4 → OrderBy
ColumnOrder=5 → FK_ContractorCompany
```

If you want to insert a new column at position 3, you must:
- Shift existing columns 3+ up by 1
- OR use a decimal (ColumnOrder=2.5)

---

### 3. CATEGORY (for dropdowns)

Groups dropdown values together. Use a clear, PascalCase name.

**Examples:**
- `ContractorStatus` — status values for contractors
- `YesNo` — boolean choices
- `ProjectPhase` — project lifecycle stages
- `City` — city names

**Rule:** All rows in APP_DROPDOWNS with the same CATEGORY form one dropdown.

---

### 4. ApplicationID

Each app (KWAT, DPW, HHMP) has a unique ApplicationID.

**To find an app's ID:**
```sql
SELECT ApplicationID, AppName FROM APP_APP_APP WHERE AppName='KWAT';
```

Use this ID when:
- Adding tables to APP_TABLES (which app can see which table)
- Creating reports
- Managing sidebar items

---

### 5. RoleID

Each user role (Admin, Manager, Viewer, etc.) has a unique RoleID.

**To find a role's ID:**
```sql
SELECT RoleID, RoleName FROM Roles WHERE RoleName='Admin';
```

Use this ID when:
- Granting/denying access via APP_GRANTS

---

## Workflow: From Database Change to UI Display

```
Day 1, 2:00 PM
├─ You: ALTER TABLE Contractor ADD EmailAddress nvarchar(100) NULL;
├─ You: EXEC development.DynamicSQUID ... (regenerate procs)
├─ You: INSERT APP_TABLE_COLUMNS for EmailAddress
│
Day 1, 2:15 PM (User's browser, old metadata cached)
├─ User: Still doesn't see EmailAddress column
├─ User: Hard-refreshes (Ctrl+Shift+R)
├─ Browser: Clears local cache
├─ Browser: Calls Services servlet for new metadata
├─ Services servlet: Queries KWATControl database
├─ Services servlet: Caches result (in server memory)
├─ Services servlet: Returns JSON to browser
├─ Browser: Renders table with new EmailAddress column ✓
│
Day 1, 2:30 PM (Other user's browser, server cache active)
├─ Other user: Loads page normally
├─ Services servlet: Cache hit! Returns cached metadata (fast)
├─ Browser: Renders table with EmailAddress column ✓
│
Day 1, 3:00 PM (after 60-min server cache expires)
├─ Third user: Loads page
├─ Services servlet: Cache miss, queries database again
├─ Services servlet: Caches new result
├─ Browser: Renders with EmailAddress column ✓
```

**Key point:** Changes are visible immediately to you (when testing), but there's a delay for other users due to caching. That's why we hard-refresh and tell users to do the same.

---

## Quick Decision Tree

```
What do you want to do?

1. Add a new column to a table?
   → See: add-contractor-columns.md
   → Do: ALTER TABLE, DynamicSQUID, INSERT APP_TABLE_COLUMNS
   
2. Create a dropdown/lookup list?
   → See: dropdowns-and-lookups.md
   → Do: INSERT APP_DROPDOWNS, UPDATE APP_TABLE_COLUMNS
   
3. Hide a column for certain users?
   → See: quick-reference.md (Grant Access section)
   → Do: UPDATE APP_TABLE_COLUMNS (Visible=0) or INSERT APP_GRANTS
   
4. Add a new report?
   → See: quick-reference.md (Add a Report section)
   → Do: INSERT APP_REPORTS, INSERT APP_REPORT_PARAMS
   
5. Update sidebar navigation?
   → See: quick-reference.md (Add Sidebar Menu Item section)
   → Do: INSERT APP_SIDEBAR
   
6. Users aren't seeing my changes?
   → See: cache-invalidation.md
   → Do: Hard-refresh browser (Ctrl+Shift+R)
   
7. Want to understand how the whole system works?
   → See: architecture-flow.md
   → Read: Page load sequence, caching layers, data flow diagram
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting to regenerate SQUID procedures

**Wrong:**
```sql
ALTER TABLE Contractor ADD NewColumn nvarchar(100) NULL;
-- Forgot to run DynamicSQUID!
INSERT APP_TABLE_COLUMNS ... (for NewColumn)
```

**Result:** Column appears in UI, but saving fails (proc doesn't have parameter).

**Right:**
```sql
ALTER TABLE Contractor ADD NewColumn nvarchar(100) NULL;
EXEC development.DynamicSQUID @Schema='dbo', @Table='Contractor', @DoDrops=1;
INSERT APP_TABLE_COLUMNS ... (for NewColumn)
```

---

### ❌ Mistake 2: ColumnOrder not sequential

**Wrong:**
```sql
INSERT APP_TABLE_COLUMNS (ColumnOrder) VALUES (1), (3), (5);  -- Gaps!
```

**Result:** Columns may not render in expected order or UI behaves oddly.

**Right:**
```sql
INSERT APP_TABLE_COLUMNS (ColumnOrder) VALUES (1), (2), (3);  -- Sequential
```

---

### ❌ Mistake 3: DropdownSource CATEGORY doesn't exist

**Wrong:**
```sql
UPDATE APP_TABLE_COLUMNS SET DropdownSource='NonExistent' WHERE ColumnID=123;
-- Forgot to INSERT into APP_DROPDOWNS first!
```

**Result:** Dropdown appears empty (no values shown).

**Right:**
```sql
INSERT APP_DROPDOWNS (CATEGORY, KEY, VALUE) VALUES ('MyCategory', 'KEY1', 'Display');
UPDATE APP_TABLE_COLUMNS SET DropdownSource='MyCategory' WHERE ColumnID=123;
```

---

### ❌ Mistake 4: Using DELETE instead of UPDATE Visible=0

**Wrong:**
```sql
DELETE FROM APP_TABLE_COLUMNS WHERE ColumnID=123;
```

**Result:** Lost configuration history; if you need to restore, it's gone.

**Right:**
```sql
UPDATE APP_TABLE_COLUMNS SET Visible=0 WHERE ColumnID=123;
-- Or set Active=0 to disable entirely
```

---

## Next Steps

1. **Pick a scenario** from the [Decision Tree](#quick-decision-tree) above.
2. **Read the relevant guide** (add-contractor-columns.md, dropdowns-and-lookups.md, etc.).
3. **Copy the SQL** and adapt for your table/column/app.
4. **Test in your database** (sql-dev, sql-itmd).
5. **Hard-refresh browser** to see the UI change.
6. **If it doesn't work**, check [cache-invalidation.md](references/cache-invalidation.md).

---

## Resources

| Resource | Purpose |
|---|---|
| [SKILL.md](SKILL.md) | Full documentation of all KWATControl tables |
| [quick-reference.md](references/quick-reference.md) | SQL queries for common operations |
| [architecture-flow.md](references/architecture-flow.md) | System design, page load, caching, data flow |
| [cache-invalidation.md](references/cache-invalidation.md) | Troubleshooting: "Why isn't my change visible?" |
| [add-contractor-columns.md](examples/add-contractor-columns.md) | Worked example: Add EmailAddress + ServicesProvided |
| [dropdowns-and-lookups.md](examples/dropdowns-and-lookups.md) | Worked example: Create ContractorStatus dropdown |

---

## Still Have Questions?

**Q: Where is KWATControl located?**  
A: Server `sql-itmd`, Database `KWATControl`

**Q: What databases use KWATControl for UI config?**  
A: All MSSQL-based web apps: KWAT, DPW apps, HHMP, etc.

**Q: Do I need to edit both sql-dev and sql-itmd?**  
A: Usually yes. Edit sql-dev for physical table changes (ALTER TABLE, SQUID), then sql-itmd for UI config (APP_TABLE_COLUMNS, etc.).

**Q: How do I know which ApplicationID is which?**  
A: Query `SELECT ApplicationID, AppName FROM APP_APP_APP;`

**Q: Can I delete old dropdown values?**  
A: Not recommended (data loss risk). Use `UPDATE ... SET VALUE='[DEPRECATED]...'` instead.

**Q: How long does it take for changes to show?**  
A: Immediately (after hard-refresh). Server cache delays 15-60 min for other users.

**Q: Do I need to restart anything?**  
A: Only if server cache doesn't expire (admin can restart servlet if urgent).
