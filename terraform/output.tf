# ============================================================
# OUTPUTS: Was wollen wir nach dem Bauen wissen?
# Analogie: Nach dem Hausbau bekommst du eine Zusammenfassung
# "Deine Adresse ist X, deine Hausnummer ist Y"
# ============================================================

output "s3_bucket_name" {
  description = "Name des S3-Buckets"
  value       = aws_s3_bucket.energy_data.bucket
}

output "s3_bucket_arn" {
  description = "ARN des S3-Buckets"
  value       = aws_s3_bucket.energy_data.arn
}

output "sqs_queue_url" {
  description = "URL der SQS-Queue"
  value       = aws_sqs_queue.energy_data.url
}

output "sqs_queue_arn" {
  description = "ARN der SQS-Queue"
  value       = aws_sqs_queue.energy_data.arn
}

output "sqs_dlq_url" {
  description = "URL der Dead Letter Queue"
  value       = aws_sqs_queue.energy_data_dlq.url
}


output "lambda_function_name" {
  description = "Name der Lambda Funktion"
  value       = aws_lambda_function.energy_processor.function_name
}

output "lambda_function_arn" {
  description = "ARN der Lambda Funktion"
  value       = aws_lambda_function.energy_processor.arn
}