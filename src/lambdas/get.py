from common import log, response, get_table


def lambda_handler(event, context):
    note_id = None
    try:
        path_params = event.get("pathParameters") or {}
        note_id = path_params.get("id")
        if not note_id:
            raise ValueError("id path parameter is required")

        log("INFO", "get", note_id=note_id)
        
        table = get_table()
        result = table.get_item(Key={"id": note_id})
        
        item = result.get("Item")
        if not item:
            return response(404, {"error": "Note not found"})
        return response(200, item)
    except ValueError as exc:
        return response(400, {"error": str(exc)})
    except Exception:
        log("ERROR", "unexpected error", aws_request_id=context.aws_request_id)
        return response(500, {"error": "Internal server error"})