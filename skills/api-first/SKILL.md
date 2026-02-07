---
name: api-first
description: API contract design workflow. Consumer-first resource modeling, error format standardization, and OpenAPI specification.
---

When this skill is active, follow this 7-step discipline when designing an API:

## 1. Start from the Consumer

Design the API from the caller's perspective before writing any server code:
- List every screen, workflow, or integration that will call this API
- For each consumer, write the ideal request and response — what would make integration trivial?
- Identify shared resources across consumers — these become your API entities
- Document the sequence of calls needed for each workflow

## 2. Model Resources

Map domain concepts to REST resources:
- Nouns for resources (`/users`, `/orders`), verbs for actions that don't fit CRUD (`/orders/{id}/cancel`)
- Use plural nouns consistently: `/users/{id}`, not `/user/{id}`
- Nest only for strong parent-child relationships: `/users/{id}/addresses` — flatten everything else
- Keep URLs shallow — max 2 levels of nesting

## 3. Define Request and Response Shapes

Design the data contract for each endpoint:
- Use consistent field naming: `camelCase` for JSON, `snake_case` for query parameters
- Include only fields the consumer needs — no internal IDs, timestamps, or metadata unless requested
- Use envelope responses for collections: `{ "data": [...], "meta": { "total": 100, "page": 1 } }`
- Support partial responses with `?fields=name,email` for bandwidth-sensitive clients

## 4. Standardize Error Responses

Every error follows the same structure:
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Human-readable description",
    "details": [{ "field": "email", "issue": "must be a valid email" }]
  }
}
```
- Use machine-readable `code` for client logic, `message` for display
- Map codes to HTTP status: 400 for validation, 401 for auth, 404 for missing, 409 for conflict, 429 for rate limit
- Include `details` array for field-level validation errors
- Never expose stack traces, SQL errors, or internal paths in error responses

## 5. Design Authentication and Authorization

Plan the security model before implementing endpoints:
- Authentication: who is calling? (API key, JWT, OAuth2)
- Authorization: what can they do? (RBAC, ABAC, resource ownership)
- Apply least privilege — default deny, explicitly grant access per endpoint
- Document auth requirements per endpoint: public, authenticated, admin-only

## 6. Write the OpenAPI Specification

Produce a machine-readable contract before implementing:
- Write `openapi.yaml` (or `.json`) with paths, schemas, and examples
- Include `example` values for every schema property — consumers use these for mocking
- Use `$ref` for shared schemas — define once in `components/schemas/`, reference everywhere
- Validate the spec: `npx @redocly/cli lint openapi.yaml`

## 7. Verify the Contract

Confirm the API matches its specification:
- Generate client SDKs or types from the OpenAPI spec — if generation fails, the spec is wrong
- Write contract tests: each endpoint returns the documented status codes and response shapes
- Test error paths: invalid input, missing auth, nonexistent resources, rate limiting
- Run `npx @redocly/cli lint openapi.yaml` — zero warnings before merging
