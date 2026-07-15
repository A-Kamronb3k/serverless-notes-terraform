from common import log, response, table


def lambda_handler(event, context):
    try:
        log("INFO", "list", note_id=None)
        result = table.scan(Limit=50)
        items = result.get("Items", [])
        return response(200, {"items": items, "count": len(items)})
    except ValueError as exc:
        return response(400, {"error": str(exc)})
    except Exception:
        log("ERROR", "unexpected error", aws_request_id=context.aws_request_id)
        return response(500, {"error": "Internal server error"})
