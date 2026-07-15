from datetime import datetime, timezone

from botocore.exceptions import ClientError

from common import log, parse_body, response, table, validate_note


def lambda_handler(event, context):
    note_id = None
    try:
        path_params = event.get("pathParameters") or {}
        note_id = path_params.get("id")
        if not note_id:
            raise ValueError("id path parameter is required")

        data = validate_note(parse_body(event), partial=True)
        log("INFO", "update", note_id=note_id)

        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        update_parts = ["#updated_at = :updated_at"]
        names = {"#updated_at": "updated_at"}
        values = {":updated_at": now}

        if "title" in data:
            update_parts.append("#title = :title")
            names["#title"] = "title"
            values[":title"] = data["title"]
        if "content" in data:
            update_parts.append("#content = :content")
            names["#content"] = "content"
            values[":content"] = data["content"]

        result = table.update_item(
            Key={"id": note_id},
            UpdateExpression="SET " + ", ".join(update_parts),
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ConditionExpression="attribute_exists(id)",
            ReturnValues="ALL_NEW",
        )
        return response(200, result["Attributes"])
    except ClientError as exc:
        if exc.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return response(404, {"error": "Note not found"})
        log("ERROR", "unexpected error", aws_request_id=context.aws_request_id)
        return response(500, {"error": "Internal server error"})
    except ValueError as exc:
        return response(400, {"error": str(exc)})
    except Exception:
        log("ERROR", "unexpected error", aws_request_id=context.aws_request_id)
        return response(500, {"error": "Internal server error"})
