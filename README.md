# Serverless Notes App (AWS + Terraform)
[![CI/CD Pipeline](https://github.com/A-Kamronb3k/serverless-notes-terraform/actions/workflows/ci.yml/badge.svg)](https://github.com/A-Kamronb3k/serverless-notes-terraform/actions/workflows/ci.yml)
A full-stack, serverless single-page application (SPA) built and deployed entirely on AWS using Terraform.

## 🚀 Live Demo & API Endpoint

**🌐 Frontend App (Live):** 👉 [https://d2k6mpvowrmd9f.cloudfront.net](https://d2k6mpvowrmd9f.cloudfront.net)

This project is a fully functional serverless REST API. All requests are routed through API Gateway directly to AWS Lambda and DynamoDB.

**Base URL:**
`https://zaag9fi70j.execute-api.eu-north-1.amazonaws.com`

You can test this API using `curl`, Postman, or any frontend application of your choice. Detailed information about all endpoints, request formats, and error codes can be found in our API Reference:
👉 **[API Reference (docs/api.md)](./docs/api.md)**

## 🏗 Architecture
- **Frontend:** Vanilla JS, HTML, CSS hosted on Amazon S3 and distributed via CloudFront (with OAC enabled).
- **Backend:** API Gateway HTTP API integrated with Python Lambda functions.
- **Database:** Amazon DynamoDB.
- **Authentication:** Amazon Cognito (User Pool) with JWT authorization on the API.
- **Infrastructure as Code (IaC):** Terraform.

## 📸 Screenshots

### 1. Application Interface
![App UI](screenshots/01-app-ui.png)

### 2. Secure API (CORS configured)
![CORS Setup](screenshots/02-network-cors.png)

### 3. Mobile Responsive Design
![Mobile View](screenshots/03-mobile-view.png)

### 4. DynamoDB Records
![DynamoDB](screenshots/04-dynamodb-records.png)

### 5. Cognito Authentication Flow
![Cognito Auth](screenshots/05-auth-working.png)