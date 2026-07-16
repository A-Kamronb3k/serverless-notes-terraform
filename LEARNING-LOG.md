### Day 16 - Lambda CRUD & Terraform `for_each`
- **What broke:** Encountered an error when trying to use dynamic keys in a Terraform `depends_on` block within a `for_each` loop (`depends_on = [aws_cloudwatch_log_group.function[each.key]]`).
- **How I fixed it:** Learned that Terraform requires a static reference for `depends_on`. Fixed it by referencing the entire resource block: `depends_on = [aws_cloudwatch_log_group.function]`.
- **Note:** DynamoDB returns numbers as `Decimal` types, requiring a custom JSON encoder to avoid serialization errors during API responses.

### Day 17: API Gateway HTTP API & Terraform Integration

**Bugun nimalarni o'rgandim va bajardim:**
* **HTTP API (v2):** Klassik REST API o'rniga, zamonaviyroq, arzonroq va soddaroq bo'lgan API Gateway HTTP API ni Terraform (`aws_apigatewayv2_*` resurslari) orqali yaratdim.
* **Route va Lambda Integration:** 5 ta Lambda funksiyamni (`create`, `get`, `list`, `update`, `delete`) API Gateway'dagi mos route'larga (POST, GET, PUT, DELETE) muvaffaqiyatli uldim. Payload formati sifatida `2.0` versiyadan foydalandim.
* **Xavfsizlik va Ruxsatlar:** API Gateway Lambda funksiyalarini chaqira olishi uchun `aws_lambda_permission` orqali to'g'ri ruxsatlarni sozladim. 
* **CORS va Throttling:** Frontend dasturlar muammosiz ulanishi uchun CORS (Cross-Origin Resource Sharing) sozlamalarini va `OPTIONS` preflight so'rovlarini to'g'riladim. API'ni spamdan himoya qilish uchun Throttling (burst va rate limit) yoqildi.
* **Testing:** Barcha endpoint'larni terminaldan `curl` orqali test qildim (ma'lumot yaratish, o'qish, yangilash va o'chirish). `200 OK`, `204 No Content` va `404 Not Found` statuslari kutilganidek ishladi.