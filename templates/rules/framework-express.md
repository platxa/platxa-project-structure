## Framework Rules — Express/Node.js

- Use middleware for cross-cutting concerns (auth, logging, error handling)
- Always validate request body/params with a schema validator (zod, joi, yup)
- Use async error handling — wrap async route handlers or use express-async-errors
- Never send stack traces in production error responses
- Use `helmet` for security headers, `cors` for CORS configuration
- Keep route handlers thin — delegate business logic to service modules
