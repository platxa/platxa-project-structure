## Database Rules — MongoDB

- Always validate documents against schemas before insertion
- Use projection to limit returned fields — never fetch entire documents unnecessarily
- Create indexes for fields used in queries — check with `.explain("executionStats")`
- Avoid `$where` and JavaScript evaluation in queries (injection risk)
- Use transactions for multi-document operations that must be atomic
- Set appropriate write concern for data criticality
