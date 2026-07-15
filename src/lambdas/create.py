from datetime import datetime, timezone
from uuid import uuid4

from common import log, parse_body, response, table, validate_note


def lambda_handler(event, context):
    note_id = None
    try:
        data = validate_note(parse_body(event))
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        note_id = str(uuid4())
        item = {
            "id": note_id,
            "title": data["title"],
            "content": data.get("content", ""),
            "created_at": now,
            "updated_at": now,
        }
        log("INFO", "create", note_id=note_id)
        table.put_item(Item=item)
        return response(201, item)
    except ValueError as exc:
        return response(400, {"error": str(exc)})
    except Exception:
        log("ERROR", "unexpected error", aws_request_id=context.aws_request_id)
        return response(500, {"error": "Internal server error"})
