# Notes API Reference

HTTP API (API Gateway v2) for creating, reading, updating, and deleting notes stored in DynamoDB.

Base URL: use the Terraform output `api_endpoint` (for example `https://{api-id}.execute-api.{region}.amazonaws.com`).

Content-Type for request and response bodies: `application/json` (except `204 No Content`).

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/notes` | Create a note |
| `GET` | `/notes` | List notes (up to 50) |
| `GET` | `/notes/{id}` | Get a note by id |
| `PUT` | `/notes/{id}` | Partially update a note |
| `DELETE` | `/notes/{id}` | Delete a note |

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

Create a note.

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

List notes (DynamoDB scan, limit 50).

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

Fetch a single note by id.

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

Partial update. Send at least one of `title` or `content`. `updated_at` is refreshed server-side.

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

Delete a note by id.

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

Other example messages:

```json
{
  "error": "Invalid JSON body"
}
```

```json
{
  "error": "title must be a non-empty string"
}
```

```json
{
  "error": "Unknown fields: tags"
}
```

```json
{
  "error": "At least one of title or content is required"
}
```

```json
{
  "error": "id path parameter is required"
}
```

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
