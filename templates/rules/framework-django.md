## Framework Rules — Django

- Use class-based views for CRUD, function-based views for custom logic
- Always use the ORM — never raw SQL unless performance requires it (and document why)
- Migrations must be reversible — always define `reverse_code` or backwards operations
- Use `select_related()` / `prefetch_related()` to avoid N+1 queries
- Form validation in Django Forms or DRF Serializers, never in views
- Use `get_object_or_404()` instead of try/except for object retrieval
