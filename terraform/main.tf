# ============================================================
# PROVIDER: Terraform sagt AWS "ich bin es, ich arbeite in
# Frankfurt und tagge alles mit diesen Labels"
# ============================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================
# RANDOM ID: Gibt dem S3-Bucket einen global eindeutigen Namen
# Analogie: Wie eine Autonummer – jedes Auto braucht eine
# einzigartige Kombination
# ============================================================
resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# S3 BUCKET: Der Aktenschrank für Rohdaten
# ============================================================
resource "aws_s3_bucket" "energy_data" {
  bucket        = "${var.project_name}-energy-data-${var.environment}-${random_id.suffix.hex}"
  force_destroy = true
}

# Versionierung: Wie Git – jede Version einer Datei wird behalten
resource "aws_s3_bucket_versioning" "energy_data" {
  bucket = aws_s3_bucket.energy_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Verschlüsselung: Daten werden verschlüsselt gespeichert
resource "aws_s3_bucket_server_side_encryption_configuration" "energy_data" {
  bucket = aws_s3_bucket.energy_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Automatisches Aufräumen nach X Tagen
resource "aws_s3_bucket_lifecycle_configuration" "energy_data" {
  bucket = aws_s3_bucket.energy_data.id

  rule {
    id     = "expire-raw-data"
    status = "Enabled"

    filter {}

    expiration {
      days = var.s3_data_retention_days
    }
  }
}

# Öffentlichen Zugriff blockieren – IMMER!
resource "aws_s3_bucket_public_access_block" "energy_data" {
  bucket = aws_s3_bucket.energy_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# SQS DEAD LETTER QUEUE: Das Netz unter dem Trapez
# Nachrichten die 3x fehlschlagen landen hier
# ============================================================
resource "aws_sqs_queue" "energy_data_dlq" {
  name                      = "${var.project_name}-energy-data-dlq-${var.environment}"
  message_retention_seconds = 1209600
}

# ============================================================
# SQS MAIN QUEUE: Das Förderband
# ============================================================
resource "aws_sqs_queue" "energy_data" {
  name                       = "${var.project_name}-energy-data-${var.environment}"
  visibility_timeout_seconds = 30
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.energy_data_dlq.arn
    maxReceiveCount     = 3
  })
}