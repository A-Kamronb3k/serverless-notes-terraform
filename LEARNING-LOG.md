### Day 16 - Lambda CRUD & Terraform `for_each`
- **What broke:** Encountered an error when trying to use dynamic keys in a Terraform `depends_on` block within a `for_each` loop (`depends_on = [aws_cloudwatch_log_group.function[each.key]]`).
- **How I fixed it:** Learned that Terraform requires a static reference for `depends_on`. Fixed it by referencing the entire resource block: `depends_on = [aws_cloudwatch_log_group.function]`.
- **Note:** DynamoDB returns numbers as `Decimal` types, requiring a custom JSON encoder to avoid serialization errors during API responses.