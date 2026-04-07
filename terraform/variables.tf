variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Präfix für alle Ressourcen-Namen"
  type        = string
  default     = "smart-grid"
}

variable "environment" {
  description = "Deployment-Umgebung"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Umgebung muss 'dev', 'staging' oder 'prod' sein."
  }
}

variable "s3_data_retention_days" {
  description = "Wie viele Tage werden Rohdaten in S3 aufbewahrt?"
  type        = number
  default     = 90
}

variable "sqs_message_retention_seconds" {
  description = "Wie lange hält SQS eine Nachricht?"
  type        = number
  default     = 86400
}