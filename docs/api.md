# Notes API Reference

HTTP API (API Gateway v2) for creating, reading, updating, and deleting notes stored in DynamoDB.

**Base URL:** `https://zaag9fi70j.execute-api.eu-north-1.amazonaws.com`

**Content-Type** for request and response bodies: `application/json` (except `204 No Content`).

## 🔒 Security & Authentication
The API is protected by **Amazon Cognito**. 
- `GET /notes` and `GET /notes/{id}` are **public** (no authentication required).
- `POST`, `PUT`, and `DELETE` methods require a valid JWT token. 
You must include the token in the headers of your request:
`Authorization: Bearer <your_cognito_jwt_token>`

## Endpoints

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| `POST` | `/notes` | Create a note | Yes (JWT) |
| `GET` | `/notes` | List notes (up to 50) | No |
| `GET` | `/notes/{id}` | Get a note by id | No |
| `PUT` | `/notes/{id}` | Partially update a note | Yes (JWT) |
| `DELETE` | `/notes/{id}` | Delete a note | Yes (JWT) |

### Note object

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Generated on create |
| `title` | string | Required on create; max 200 characters |
| `content` | string | Optional; max 5000 characters; defaults to `""` on create if omitted |
| `created_at` | string | ISO 8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`) |
| `updated_at` | string | ISO 8601 UTC; set on create and update |

Unknown body fields are rejected. Only `title` and `content` are accepted in request bodies.

---

## `POST /notes`

Create a note. **Requires Authentication.**

**Request**

```json
{
  "title": "Shopping list",
  "content": "Milk, eggs, bread"
}
```

`content` may be omitted:

```json
{
  "title": "Quick note"
}
```

**Response** — `201 Created`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Shopping list",
  "content": "Milk, eggs, bread",
  "created_at": "2026-07-16T10:22:00Z",
  "updated_at": "2026-07-16T10:22:00Z"
}
```

---

## `GET /notes`

List notes (DynamoDB scan, limit 50). **Public.**

**Request** — no body.

**Response** — `200 OK`

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Shopping list",
      "content": "Milk, eggs, bread",
      "created_at": "2026-07-16T10:22:00Z",
      "updated_at": "2026-07-16T10:22:00Z"
    }
  ],
  "count": 1
}
```

---

## `GET /notes/{id}`

Fetch a single note by id. **Public.**

**Request** — no body. Path parameter `id` is required.

**Response** — `200 OK`

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Shopping list",
  "content": "Milk, eggs, bread",
  "created_at": "2026-07-16T10:22:00Z",
  "updated_at": "2026-07-16T10:22:00Z"
}
```

---

## `PUT /notes/{id}`

Partial update. Send at least one of `title` or `content`. `updated_at` is refreshed server-side. **Requires Authentication.**

**Request**

```json
{
  "title": "Updated title",
  "content": "Updated body"
}
```

Title only:

```json
{
  "title": "Updated title"
}
```

**Response** — `200 OK` (full note after update)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Updated title",
  "content": "Updated body",
  "created_at": "2026-07-16T10:22:00Z",
  "updated_at": "2026-07-16T11:05:30Z"
}
```

---

## `DELETE /notes/{id}`

Delete a note by id. **Requires Authentication.**

**Request** — no body. Path parameter `id` is required.

**Response** — `204 No Content` (empty body)

---

## Errors

All error responses use a JSON body with an `error` field (except where noted).

### `400 Bad Request`
Invalid JSON, missing/invalid fields, or validation failures.

```json
{
  "error": "title is required"
}
```

### `401 Unauthorized`
Missing or invalid JWT token in the `Authorization` header for protected routes.

### `404 Not Found`
Note does not exist (get, update, or delete).

```json
{
  "error": "Note not found"
}
```

### `500 Internal Server Error`
Unexpected failure. Message is generic; details are not returned to the client.

```json
{
  "error": "Internal server error"
}
```