## Database Rules — PostgreSQL

- Always use parameterized queries — never build SQL with f-strings or string concatenation
- Migrations must be backward-compatible (no column drops without deprecation)
- Add indexes for columns used in WHERE, JOIN, and ORDER BY clauses
- Use connection pooling — never open/close connections per request
- Wrap multi-table operations in transactions with proper rollback on error
- Use `EXPLAIN ANALYZE` to verify query performance before merging
