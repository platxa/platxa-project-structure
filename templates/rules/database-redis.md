## Database Rules — Redis

- Always set TTL on cache keys — no indefinite caching without justification
- Use pipelines for multiple sequential commands to reduce round trips
- Never store sensitive data (passwords, tokens) in Redis without encryption
- Use appropriate data structures (hashes for objects, sorted sets for rankings)
- Handle connection failures gracefully — Redis is a cache, not primary storage
- Prefix keys with namespace to avoid collisions (e.g., `app:user:123`)
