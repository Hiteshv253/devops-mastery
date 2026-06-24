# Secrets Manager for API Keys
resource "aws_secretsmanager_secret" "groq_api_key" {
  name = "${var.project_name}/groq-api-key"

  tags = {
    Name        = "${var.project_name}-groq-api-key"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "groq_api_key" {
  secret_id     = aws_secretsmanager_secret.groq_api_key.id
  secret_string = var.groq_api_key
}
