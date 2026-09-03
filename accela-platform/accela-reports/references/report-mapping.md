# Accela Report Mapping

## Proven Report Pattern

Use this pattern for Accela Crystal Reports that are based on a mailed letter or record summary:

- Start with the exact sample record the requester recognizes.
- Pull owner and contact values from the record summary/contact tables.
- Pull address and tax-key style values from the record summary and parcel data.
- Pull balance or fee totals from finance/detail tables.
- Pull waiver, approval, denial, or expiration values from ASI/custom-field storage when the report text names a custom section or field.
- Use the report template only as the layout source; do not assume its copied SQL is the correct data source.

## Example Grounding Checks

For `VAC-21-00498`, verify the following before building the report SQL:

- Record type: `Building / Vacant Building`
- Public record number: `VAC-21-00498`
- Internal IDs: `21CAP / 00000 / 09XJ8`
- Owner: `B3CONTACT`
- Address: `B3ADDRES`
- Balance: `BPERMIT_DETAIL.BALANCE`
- Tax key: parcel data tied to the record
- Date line: Crystal formula using the generation date

## Do Not Guess

If a field is not obvious from the template, confirm it in `sql-dev ACCELAPROD` before writing the report SQL.

- Do not invent a table or join because a copied report used it.
- Do not rename a field from the requester’s wording until the live Accela source is known.
- Do not treat an admin-only custom field as code until the database confirms the field exists.
