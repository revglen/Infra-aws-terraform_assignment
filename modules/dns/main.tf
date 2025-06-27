resource "aws_route53_zone" "primary" {
  count = 0  # Disabled for cost
  name  = "example.com"  # Replace with your domain
}

resource "aws_route53_record" "alb" {
  count   = 0
  zone_id = aws_route53_zone.primary[0].zone_id
  name    = "shop.example.com"
  type    = "A"

  alias {
    name                   = var.alb_dns_name  # From networking module
    zone_id                = var.alb_zone_id   # From networking module
    evaluate_target_health = true
  }
}