resource "aws_api_gateway_rest_api" "checkout" {
  count       = 0  # Disabled for cost
  name        = "ecommerce-checkout-api"
  description = "Serverless checkout API"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "checkout" {
  count       = 0
  rest_api_id = aws_api_gateway_rest_api.checkout[0].id
  stage_name  = "prod"
}