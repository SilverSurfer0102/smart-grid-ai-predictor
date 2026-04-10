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


# ============================================================
# IAM ROLE: Der Werksausweis für Lambda
# ============================================================
# WARUM eine extra Role?
# Lambda ist ein AWS-Service – er kann nicht einfach auf andere
# Services zugreifen. Er braucht eine explizite Erlaubnis.
# Analogie: Auch der beste Mitarbeiter kommt ohne Ausweis
# nicht durch die Sicherheitsschleuse.
# ============================================================

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  # Trust Policy: Wer darf diese Role überhaupt annehmen?
  # Nur Lambda-Functions – kein anderer Service!
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Berechtigung 1: Lambda darf Logs in CloudWatch schreiben
# (Ohne das sehen wir keine Fehlermeldungen!)
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Berechtigung 2: Lambda darf SQS Nachrichten lesen
resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${var.project_name}-lambda-sqs-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.energy_data.arn
      }
    ]
  })
}

# Berechtigung 3: Lambda darf in S3 schreiben
resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-lambda-s3-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.energy_data.arn}/*"
      }
    ]
  })
}

# ============================================================
# LAMBDA FUNKTION: Der Arbeiter am Förderband
# ============================================================
# Terraform zippt den Python-Code automatisch und lädt
# ihn zu AWS hoch – kein manuelles Zippen nötig!
# ============================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda/handler.py"
  output_path = "${path.module}/../src/lambda/handler.zip"
}

resource "aws_lambda_function" "energy_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-energy-processor-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.energy_data.bucket
      ENVIRONMENT = var.environment
    }
  }
}

# ============================================================
# SQS → LAMBDA TRIGGER
# ============================================================
# Das ist die "Klingel" – wenn eine SQS Nachricht ankommt,
# wird Lambda automatisch geweckt.
# ============================================================

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.energy_data.arn
  function_name    = aws_lambda_function.energy_processor.arn
  batch_size       = 1
}


# ============================================================
# API GATEWAY: Die offizielle Eingangstür
# ============================================================
# HTTP API ist günstiger und einfacher als REST API.
# Für unser Projekt völlig ausreichend.
# ============================================================

resource "aws_apigatewayv2_api" "sensor_api" {
  name          = "${var.project_name}-sensor-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET"]
    allow_headers = ["Content-Type"]
  }
}

# Stage: Eine "Umgebung" innerhalb der API
# Analogie: Wie ein Stockwerk im Gebäude – wir nutzen "dev"
resource "aws_apigatewayv2_stage" "sensor_api" {
  api_id      = aws_apigatewayv2_api.sensor_api.id
  name        = var.environment
  auto_deploy = true
}

# IAM Role damit API Gateway in SQS schreiben darf
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-api-gateway-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# API Gateway darf SQS Nachrichten schicken
resource "aws_iam_role_policy" "api_gateway_sqs" {
  name = "${var.project_name}-api-gateway-sqs-policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.energy_data.arn
    }]
  })
}

# Integration: API Gateway → SQS direkt
# Kein Lambda dazwischen – direkt ins Förderband
resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id             = aws_apigatewayv2_api.sensor_api.id
  integration_type   = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  credentials_arn    = aws_iam_role.api_gateway_role.arn

  request_parameters = {
    "QueueUrl"    = aws_sqs_queue.energy_data.url
    "MessageBody" = "$request.body"
  }

  payload_format_version = "1.0"
}

# Route: Welcher URL-Pfad löst was aus?
# POST /sensor → SQS Integration
resource "aws_apigatewayv2_route" "sensor_route" {
  api_id    = aws_apigatewayv2_api.sensor_api.id
  route_key = "POST /sensor"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

# ── EventBridge Scheduler ──────────────────────────────────────────────────
# IAM Role: Erlaubnis für EventBridge, Lambda aufzurufen
resource "aws_iam_role" "eventbridge_role" {
  name = "smart-grid-eventbridge-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_lambda_invoke" {
  name = "smart-grid-eventbridge-invoke-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = aws_lambda_function.energy_processor.arn
    }]
  })
}

# Der Scheduler selbst – klopft alle 15 Minuten bei Lambda an
resource "aws_scheduler_schedule" "solar_forecast" {
  name                         = "smart-grid-solar-forecast-${var.environment}"
  schedule_expression          = "rate(15 minutes)"
  schedule_expression_timezone = "Europe/Berlin"

  flexible_time_window {
    mode = "OFF"  # Genau zum Zeitpunkt auslösen, kein Spielraum
  }

  target {
    arn      = aws_lambda_function.energy_processor.arn
    role_arn = aws_iam_role.eventbridge_role.arn

    input = jsonencode({
      source      = "aws.scheduler"
      detail-type = "Scheduled Event"
      detail      = { trigger = "solar_forecast_15min" }
    })
  }
}

