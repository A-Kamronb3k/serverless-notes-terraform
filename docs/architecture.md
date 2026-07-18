# Serverless Notes Architecture

## 1. Terraform State Management
We do not store the Terraform state file locally. Instead, the state is hosted securely in an **AWS S3 Bucket** and locked using an **Amazon DynamoDB table**. This ensures remote state preservation, prevents data loss, and avoids state corruption or race conditions when collaborating in a team environment.

## 2. Frontend Hosting & Delivery
- **Amazon S3:** Stores the static assets (HTML, CSS, Vanilla JS) of the Single Page Application. Direct public access to the bucket is strictly blocked.
- **Amazon CloudFront:** Acts as a global Content Delivery Network (CDN) to serve the frontend securely over HTTPS. It retrieves assets from the S3 bucket using Origin Access Control (OAC), ensuring the bucket remains completely private.

## 3. API Gateway & Routing
- **Amazon API Gateway (HTTP API v2):** Routes all incoming HTTP traffic to the appropriate backend services.
- **CORS Setup:** Strictly configured to accept cross-origin requests only from the specific CloudFront distribution domain to prevent unauthorized access from third-party sites.

## 4. Lambda API (CRUD Backend)
- **Compute:** 5 separate AWS Lambda functions (Python 3.12) handle `create`, `get`, `list`, `update`, and `delete` operations.
- **IAM Design (Least-Privilege):** Each function has a dedicated IAM role restricted strictly to its required DynamoDB action (e.g., `dynamodb:PutItem` for the Create function) and scoped exclusively to its own CloudWatch Log Group.
- **Payload Format:** Handlers are designed to natively process API Gateway HTTP API v2 event formats and automatically handle JSON serialization/deserialization.

## 5. Database Layer
- **Amazon DynamoDB:** A NoSQL serverless database table configured with On-Demand capacity to store the notes. Uses `id` (String) as the primary partition key.

## 6. Security & Authentication
- **Amazon Cognito:** Manages the User Pool and provides a fully hosted UI for user sign-up and sign-in.
- **JWT Authorization:** Integrated directly into API Gateway. Read requests (`GET`) are left open for public viewing, while state-mutating requests (`POST`, `PUT`, `DELETE`) require a valid JWT token validated by the Cognito Authorizer.