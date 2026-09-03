# SQL Format Example

Use this layout when writing multi-predicate SQL queries.

```sql
SELECT
	permit.B1_ALT_ID AS PERMIT_NO,
	owner.B1_FULL_NAME AS OWNER_NAME
FROM
	dbo.B1PERMIT AS permit
LEFT JOIN
	dbo.B3CONTACT AS owner
ON 1 = 1
	AND owner.SERV_PROV_CODE = permit.SERV_PROV_CODE
	AND owner.B1_PER_ID1 = permit.B1_PER_ID1
	AND owner.B1_PER_ID2 = permit.B1_PER_ID2
	AND owner.B1_PER_ID3 = permit.B1_PER_ID3
WHERE 1 = 1
	AND permit.SERV_PROV_CODE = 'MILWAUKEE'
	AND permit.B1_ALT_ID = UPPER('{?ALTID}')
```

Notes:

- Keep clause keywords flush left.
- Put each table name on its own line after `FROM` or `JOIN`.
- Use `ON 1 = 1` and `WHERE 1 = 1` as anchors for multi-predicate clauses.
- Indent join and filter predicates with tabs.