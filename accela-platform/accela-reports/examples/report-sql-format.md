# Report SQL Format Example

Use this layout as the default for Accela report SQL in notes, drafts, and final queries.

```sql
SELECT
	b.B1_ALT_ID AS PERMIT_NO,
	owner.B1_FULL_NAME AS OWNER_NAME
FROM
	dbo.B1PERMIT AS b
LEFT JOIN
	dbo.B3CONTACT AS owner
ON 1 = 1
	AND owner.SERV_PROV_CODE = b.SERV_PROV_CODE
	AND owner.B1_PER_ID1 = b.B1_PER_ID1
	AND owner.B1_PER_ID2 = b.B1_PER_ID2
	AND owner.B1_PER_ID3 = b.B1_PER_ID3
WHERE 1 = 1
	AND b.SERV_PROV_CODE = 'MILWAUKEE'
	AND b.B1_ALT_ID = UPPER('{?ALTID}')
```

Notes:
- Keep clause keywords flush left.
- Put each table name on its own line after `FROM` and `LEFT JOIN`.
- Indent only predicates with tabs.
- Use `ON 1 = 1` and `WHERE 1 = 1` as the clause anchors.
