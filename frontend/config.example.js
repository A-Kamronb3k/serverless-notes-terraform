/**
 * Copy this file to config.js and fill in values from Terraform outputs.
 * config.js is gitignored — do not commit environment-specific values.
 *
 * Shape:
 *   window.APP_CONFIG = {
 *     apiUrl: "https://{api-id}.execute-api.{region}.amazonaws.com",
 *     cognitoDomain: "https://{prefix}.auth.{region}.amazoncognito.com",
 *     cognitoClientId: "{app-client-id}"
 *   };
 *
 * No trailing slash on apiUrl or cognitoDomain.
 * cognitoDomain may also be just the Cognito domain prefix (without .auth...).
 */
window.APP_CONFIG = {
  apiUrl: "https://YOUR_API_ID.execute-api.eu-north-1.amazonaws.com",
  cognitoDomain: "https://YOUR_PREFIX.auth.eu-north-1.amazoncognito.com",
  cognitoClientId: "YOUR_COGNITO_CLIENT_ID",
};
