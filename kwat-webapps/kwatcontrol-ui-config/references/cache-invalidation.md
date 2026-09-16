# Cache Invalidation & Deployment Strategy

## The Caching Problem

KWATControl changes often don't appear immediately in the UI because of **three layers of caching**:

1. **Browser client-side cache** (KWATClient JavaScript)
2. **Services servlet server-side cache** (in-memory metadata)
3. **CDN / HTTP browser cache** (for CSS/JS files)

## Layer 1: Browser Cache (Most Common)

### What Gets Cached

- Table metadata (columns, dropdowns, permissions)
- Report definitions
- Sidebar structure
- Access grants

### How Long

- Duration: **Session lifetime** (until tab/browser closes)
- Scope: Single browser instance
- Refresh: Hard refresh or close+reopen tab

### How to Clear

**For Testing:**
```
Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
Dev tools: F12 → Application → Cache → Clear all
Close browser completely and reopen
```

**For Users:**
- Tell them to hard refresh (Ctrl+Shift+R)
- Or close browser completely
- Or wait for automatic session timeout (usually 30-60 min)

### Example Scenario

**You:** Add EmailAddress column to Contractor table in KWATControl  
**Result:** User still doesn't see it on their open page  
**Cause:** Their browser cached the old metadata  
**Fix:** User hard-refreshes (Ctrl+Shift+R)

---

## Layer 2: Server Cache (Services Servlet)

### What Gets Cached

- Assembled metadata (with permissions applied)
- Dropdown values
- Report SQL and parameters
- Access grant rules

### How Long

- Duration: **Configurable** (typically 15-60 minutes in production)
- Scope: Across all users accessing the same table/app
- Refresh: Servlet restart, cache invalidation call, or TTL expires

### How to Clear

**Option A: Wait**
```
Server cache expires automatically after TTL (e.g., 60 minutes)
No immediate action needed for non-urgent changes
```

**Option B: Restart Servlet** (if you have admin access)
```
1. Stop KWATControlMSSQL servlet in app server (Tomcat, etc.)
2. Clear Tomcat temp/cache directories
3. Restart servlet
4. Users refresh browser
```

**Option C: Manual Cache Clear** (if app supports it)
```
Call Services servlet with cache-clear action:
GET /kwat/Services?action=ClearMetadataCache&app=KWAT

(Implementation varies by app version; check with admin)
```

**Option D: Invalidate Specific Entry** (if app supports it)
```
GET /kwat/Services?action=InvalidateTableCache&table=Contractor
```

### Example Scenario

**You:** Update EmailAddress DisplayName from "Email" to "Email Address" in APP_TABLE_COLUMNS  
**Result:** Column header still says "Email" for all users  
**Cause:** Server cached the old metadata with old label  
**Fix:** 
- Wait 60 minutes for cache TTL, OR
- Admin restarts servlet, OR
- Bounce Tomcat/app server

---

## Layer 3: CDN / HTTP Browser Cache

### What Gets Cached

- JavaScript libraries (KWATClient.js)
- CSS stylesheets
- Static images
- Minified/bundled assets

### How Long

- Duration: **Configurable headers** (HTTP Cache-Control headers)
- Scope: Browser + CDN + intermediate proxies
- Refresh: Hard refresh, manual cache clear, or cache-busting headers

### How to Clear

**For Users:**
- Hard refresh (Ctrl+Shift+R)
- Shift+F5
- Ctrl+F5

**For DevOps/Admin:**
- Update CSS/JS file version numbers (cache-busting)
- Modify HTTP Cache-Control headers to shorter TTL
- CDN purge (if using CDN like Cloudflare)
- Add `?v=123` query parameter to asset URLs

### Example Scenario

**You:** Fix a bug in KWATClient.js  
**Result:** Users still see the buggy behavior  
**Cause:** Browser cached the old .js file  
**Fix:** Users hard-refresh (Ctrl+Shift+R)

---

## Deployment Checklist

### For Small Changes (Testing/Dev)

```
1. Make change in KWATControl (e.g., add column to APP_TABLE_COLUMNS)
2. Hard refresh your browser (Ctrl+Shift+R)
3. Verify change appears
4. Done (cache will expire naturally)
```

### For Production Deployment

```
1. Make change in KWATControl (sql-itmd)
2. Verify in test environment (hard refresh browser)
3. Schedule change at low-traffic time (if possible)
4. Notify users: "Please hard-refresh (Ctrl+Shift+R) for new features"
5. Monitor for issues (check app logs)
6. If widespread issue, roll back or restart servlet

Timing:
- Small metadata changes (column labels, visibility): 5 minutes
- New columns/dropdowns: 15-30 minutes (includes testing)
- Access control changes: 30-60 minutes (critical, requires verification)
```

### For Urgent Changes (If Cache Won't Expire)

```
1. Restart KWATControlMSSQL servlet:
   - SSH into app server
   - Stop Tomcat: bin/catalina.sh stop
   - Clear cache: rm -rf temp/* work/*
   - Start Tomcat: bin/catalina.sh start
   
2. Tell users to hard-refresh (Ctrl+Shift+R)

3. Verify in production:
   - Check that metadata API returns new values
   - Test in multiple browsers/incognito mode
   - Monitor error logs
```

---

## Troubleshooting Cache Issues

### Problem: "I changed the column label but users still see the old name"

**Diagnosis:**
```sql
-- Verify change is in database
SELECT DisplayName FROM APP_TABLE_COLUMNS 
WHERE TableID=42 AND ColumnName='EmailAddress';
-- Result should show your new label
```

**Solution:**
1. Confirm change is in database ✓
2. Hard refresh browser (Ctrl+Shift+R)
3. If still not working after hard refresh:
   - Open dev tools (F12)
   - Network tab → Clear cache
   - Reload page
4. If still not working:
   - Request admin to restart servlet
   - Or wait 60 minutes for cache TTL

### Problem: "I added a dropdown but the values don't show"

**Diagnosis:**
```sql
-- Verify dropdown exists in database
SELECT ID, CATEGORY, KEY, VALUE 
FROM APP_DROPDOWNS 
WHERE CATEGORY = 'ContractorServices'
ORDER BY KEY;
-- Result should show all your dropdown values
```

**Solution:**
1. Confirm dropdown exists in database ✓
2. Verify DropdownSource column name matches EXACTLY (case-sensitive)
3. Hard refresh (Ctrl+Shift+R)
4. Check Services servlet logs for errors
5. If still not working, admin should restart servlet

### Problem: "Access grant changes aren't taking effect"

**Diagnosis:**
```sql
-- Verify grant is in database
SELECT RoleID, TableID, ColumnID, AllowRead, AllowCreate, AllowUpdate, AllowDelete
FROM APP_GRANTS
WHERE RoleID = 5 AND TableID = 42;
-- Result should show expected permissions
```

**Solution:**
1. Confirm grant is in database ✓
2. Verify user has correct RoleID (may not be what you think)
3. Hard refresh (Ctrl+Shift+R)
4. Logout and log back in (clears session)
5. Request admin to restart servlet (server cache)
6. Check app logs for permission errors

### Problem: "New columns I added to APP_TABLE_COLUMNS show in metadata but not in the UI"

**Diagnosis:**
```sql
-- Check if new column exists in physical database
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Contractor' AND COLUMN_NAME='NewField';
-- If NULL/empty, column doesn't exist in physical table

-- Check if SQUID proc was regenerated
EXEC sp_help 'UpdateContractorByPK';
-- Look at parameters; should include @NewField
```

**Solution:**
1. If physical column doesn't exist:
   ```sql
   ALTER TABLE Contractor ADD NewField nvarchar(100) NULL;
   EXEC development.DynamicSQUID @Schema='dbo', @Table='Contractor', @DoDrops=1;
   ```
2. If SQUID proc wasn't regenerated:
   ```sql
   EXEC development.DynamicSQUID @Schema='dbo', @Table='Contractor', @DoDrops=1;
   ```
3. Hard refresh browser
4. Restart servlet if needed

---

## Quick Reference: What to Do When

| Change Type | Immediate Visible? | How to Make It Visible |
|---|---|---|
| Change column label | No | Hard refresh (Ctrl+Shift+R) |
| Add/remove column | No | Hard refresh (Ctrl+Shift+R) |
| Hide/show column | No | Hard refresh (Ctrl+Shift+R) |
| Add dropdown | No | Hard refresh (Ctrl+Shift+R) |
| Change access grant | No | Logout/login + hard refresh |
| Edit report SQL | No | Restart servlet |
| Update sidebar | No | Hard refresh (Ctrl+Shift+R) |
| Change SQUID proc | No | Always restart servlet + hard refresh |

---

## Prevention: Cache-Aware Design

### When Making Changes

1. **Always verify in database first**
   ```sql
   SELECT * FROM APP_TABLE_COLUMNS WHERE TableID=42 ORDER BY ColumnOrder;
   ```

2. **Hard refresh your browser after each change**
   ```
   Ctrl+Shift+R (Windows/Linux)
   Cmd+Shift+R (Mac)
   ```

3. **Test in incognito/private mode** (skips browser cache)
   ```
   Ctrl+Shift+N (Windows) or Cmd+Shift+N (Mac)
   ```

4. **For production, notify users early**
   - "We'll be updating the UI at 2 PM; you may need to hard-refresh"
   - Provide refresh instructions (many users don't know Ctrl+Shift+R)

5. **For urgent production issues, restart the servlet**
   - Don't rely on cache TTL expiring
   - Restart is faster than waiting

### Environment Differences

| Environment | Default Cache TTL | How to Clear |
|---|---|---|
| Development | 5-15 minutes | Hard refresh or restart servlet |
| Test/Staging | 15-30 minutes | Hard refresh or request admin |
| Production | 30-60 minutes | Notify users + restart servlet |

---

**See Also:**
- [quick-reference.md](quick-reference.md) — SQL query examples
- [architecture-flow.md](architecture-flow.md) — How metadata flows through the system
- [add-contractor-columns.md](../examples/add-contractor-columns.md) — Step-by-step example
