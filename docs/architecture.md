# Serverless Notes Architecture

## Terraform State
Biz Terraform state faylini lokal kompyuterda emas, AWS S3'da saqlaymiz va DynamoDB orqali qulflaymiz (lock). Bu bizga fayl yo'qolishining oldini olishga va jamoada ishlaganda to'qnashuvlar bo'lmasligiga yordam beradi.