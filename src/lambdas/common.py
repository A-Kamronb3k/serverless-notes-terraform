import json
import os
from decimal import Decimal
from functools import lru_cache

import boto3


@lru_cache
def get_table():
    return boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            if obj % 1 == 0:
                return int(obj)
            return float(obj)
        return super().default(obj)


def log(level, message, **kwargs):
    print(json.dumps({"level": level, "message": message, **kwargs}, default=str))


def response(status_code, body=None):
    result = {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
    }
    if status_code != 204 and body is not None:
        result["body"] = json.dumps(body, cls=DecimalEncoder)
    return result


def parse_body(event):
    raw = event.get("body") or ""
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, TypeError) as exc:
        raise ValueError("Invalid JSON body") from exc


def validate_note(data, partial=False):
    if not isinstance(data, dict):
        raise ValueError("Request body must be a JSON object")

    allowed = {"title", "content"}
    unknown = set(data.keys()) - allowed
    if unknown:
        raise ValueError(f"Unknown fields: {', '.join(sorted(unknown))}")

    cleaned = {}

    if "title" in data:
        title = data["title"]
        if not isinstance(title, str) or not title.strip():
            raise ValueError("title must be a non-empty string")
        if len(title) > 200:
            raise ValueError("title must be at most 200 characters")
        cleaned["title"] = title
    elif not partial:
        raise ValueError("title is required")

    if "content" in data:
        content = data["content"]
        if not isinstance(content, str):
            raise ValueError("content must be a string")
        if len(content) > 5000:
            raise ValueError("content must be at most 5000 characters")
        cleaned["content"] = content

    if partial and not cleaned:
        raise ValueError("At least one of title or content is required")

    return cleaned