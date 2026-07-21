import os
import sys
import pytest
import boto3
from moto import mock_aws

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src/lambdas')))

os.environ["TABLE_NAME"] = "notes-test"
os.environ["AWS_DEFAULT_REGION"] = "eu-north-1"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["AWS_SECURITY_TOKEN"] = "testing"
os.environ["AWS_SESSION_TOKEN"] = "testing"

@pytest.fixture(autouse=True)
def clear_cache():
    from common import get_table
    get_table.cache_clear()
    yield

@pytest.fixture
def dynamodb_table():
    with mock_aws():
        dynamodb = boto3.resource("dynamodb", region_name="eu-north-1")
        table = dynamodb.create_table(
            TableName="notes-test",
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST"
        )
        yield table

@pytest.fixture
def api_event():
    def _builder(body=None, path_parameters=None):
        import json
        event = {}
        if body is not None:
            event["body"] = json.dumps(body) if isinstance(body, dict) else body
        if path_parameters is not None:
            event["pathParameters"] = path_parameters
        return event
    return _builder

@pytest.fixture
def mock_context():
    return type("MockContext", (), {"aws_request_id": "test-req-id-123"})()