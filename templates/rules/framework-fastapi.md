## Framework Rules — FastAPI

- Use Pydantic models for all request/response schemas — never raw dicts
- Use `Depends()` for dependency injection — database sessions, auth, config
- Define path operations with explicit status codes: `@app.post(..., status_code=201)`
- Use `HTTPException` for error responses — never return error dicts with 200
- Background tasks via `BackgroundTasks`, not threads or asyncio.create_task
- Use `async def` for I/O-bound endpoints, `def` for CPU-bound
