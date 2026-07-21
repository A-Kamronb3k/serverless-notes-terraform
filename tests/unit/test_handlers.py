import json
import pytest

import create
import get
import list
import update
import delete

# --- CREATE TESTS ---
def test_create_note_success(dynamodb_table, api_event, mock_context):
    event = api_event(body={"title": "Test Title", "content": "Test Content"})
    response = create.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 201
    body = json.loads(response["body"])
    assert "id" in body
    assert body["title"] == "Test Title"

def test_create_note_missing_title(dynamodb_table, api_event, mock_context):
    event = api_event(body={"content": "No title here"})
    response = create.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 400

def test_create_note_invalid_json(dynamodb_table, api_event, mock_context):
    event = api_event(body="invalid { json")
    response = create.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 400

# --- GET TESTS ---
def test_get_note_success(dynamodb_table, api_event, mock_context):
    dynamodb_table.put_item(Item={"id": "123", "title": "Get Me"})
    
    event = api_event(path_parameters={"id": "123"})
    response = get.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["title"] == "Get Me"

def test_get_note_not_found(dynamodb_table, api_event, mock_context):
    event = api_event(path_parameters={"id": "non-existent"})
    response = get.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 404

# --- LIST TESTS ---
def test_list_notes_empty(dynamodb_table, api_event, mock_context):
    event = api_event()
    response = list.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["count"] == 0

def test_list_notes_with_items(dynamodb_table, api_event, mock_context):
    dynamodb_table.put_item(Item={"id": "1", "title": "A"})
    dynamodb_table.put_item(Item={"id": "2", "title": "B"})
    
    event = api_event()
    response = list.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["count"] == 2

# --- UPDATE TESTS ---
def test_update_note_success(dynamodb_table, api_event, mock_context):
    dynamodb_table.put_item(Item={"id": "123", "title": "Old"})
    
    event = api_event(path_parameters={"id": "123"}, body={"title": "New Title"})
    response = update.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["title"] == "New Title"

def test_update_note_empty_payload(dynamodb_table, api_event, mock_context):
    dynamodb_table.put_item(Item={"id": "123", "title": "Old"})
    event = api_event(path_parameters={"id": "123"}, body={})
    response = update.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 400

# --- DELETE TESTS ---
def test_delete_note_success(dynamodb_table, api_event, mock_context):
    dynamodb_table.put_item(Item={"id": "123", "title": "To Delete"})
    
    event = api_event(path_parameters={"id": "123"})
    response = delete.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 204
    assert dynamodb_table.get_item(Key={"id": "123"}).get("Item") is None

def test_delete_note_not_found(dynamodb_table, api_event, mock_context):
    event = api_event(path_parameters={"id": "404-id"})
    response = delete.lambda_handler(event, mock_context)
    
    assert response["statusCode"] == 404