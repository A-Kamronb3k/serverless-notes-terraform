### Day 16 - Lambda CRUD & Terraform `for_each`
- **What broke:** Encountered an error when trying to use dynamic keys in a Terraform `depends_on` block within a `for_each` loop (`depends_on = [aws_cloudwatch_log_group.function[each.key]]`).
- **How I fixed it:** Learned that Terraform requires a static reference for `depends_on`. Fixed it by referencing the entire resource block: `depends_on = [aws_cloudwatch_log_group.function]`.
- **Note:** DynamoDB returns numbers as `Decimal` types, requiring a custom JSON encoder to avoid serialization errors during API responses.

### Day 17 — API Gateway HTTP API + Terraform integration
- **Built:** An API Gateway **HTTP API (v2)** with Terraform (`aws_apigatewayv2_*`) — the cheaper, simpler modern alternative to REST API — and wired all five Lambda functions (`create`, `get`, `list`, `update`, `delete`) to their routes (POST/GET/PUT/DELETE) using payload format 2.0.
- **Permissions:** Granted API Gateway the right to invoke each function via `aws_lambda_permission`, keeping per-function least-privilege IAM.
- **CORS & throttling:** Configured CORS with `OPTIONS` preflight handling for the upcoming frontend, and enabled throttling (rate + burst limits) as basic abuse protection.
- **Tested:** Full CRUD cycle via `curl` — `200 OK`, `204 No Content`, and `404 Not Found` all behaved as expected.