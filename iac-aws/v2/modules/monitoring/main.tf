# modules/monitoring/main.tf
resource "aws_cloudwatch_log_group" "nginx_log_group" {
  name              = "/aws/eks/nginx-app"
  retention_in_days = 7
}

resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_xray_group" "nginx_xray" {
  group_name        = "nginx-group"
  filter_expression = "http.url CONTAINS 'nginx'"
}
