resource "aws_wafv2_web_acl" "ecommerce_waf" {
  name        = "ecommerce-waf"
  scope       = "REGIONAL"  # For ALB/API Gateway
  description = "WAF for e-commerce application"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ecommerce-waf"
    sampled_requests_enabled   = true
  }
}