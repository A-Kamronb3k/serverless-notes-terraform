# Serverless Notes Architecture

## Terraform State
Biz Terraform state faylini lokal kompyuterda emas, AWS S3'da saqlaymiz va DynamoDB orqali qulflaymiz (lock). Bu bizga fayl yo'qolishining oldini olishga va jamoada ishlaganda to'qnashuvlar bo'lmasligiga yordam beradi.

## Lambda API (CRUD)
- **Compute:** 5 separate AWS Lambda functions (Python 3.12) to handle create, get, list, update, and delete operations.
- **IAM Design (Least-Privilege):** Each function has a dedicated IAM role restricted strictly to its required DynamoDB action (e.g., `dynamodb:PutItem` for Create) and scoped strictly to its own CloudWatch Log Group.
- **Payload Format:** Handlers are designed to natively process API Gateway HTTP API v2 event formats.