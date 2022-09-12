resource "aws_wafv2_web_acl" "image-api" {
  name  = "${var.environment}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rate-limit-api"
      sampled_requests_enabled   = false
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "rate-limit-api"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "image-api" {
  resource_arn = aws_alb.ecs_cluster_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.image-api.arn
}
