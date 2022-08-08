resource "aws_cloudwatch_log_group" "sonarqube_log_group" {
  name              = "${var.name_prefix}-logs"
  retention_in_days = 30
  tags              = var.tags
}
