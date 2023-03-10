
resource "aws_lb" "pi_alb" {
  name               = "pi-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = ["sg-0330f3d740ffaeb69"]
  subnets            = ["subnet-0884c63b66e350163", "subnet-059902d9ee58cc274", "subnet-06ec00f2a6788bff5"]

  enable_deletion_protection = false

  access_logs {
    bucket  = "au-slyp-com-au-teamdata-logs"
    prefix  = "pi-alb"
    enabled = true
  }
}

resource "aws_lb_target_group" "pi_alb_tg" {
  port        = 443
  protocol    = "HTTPS"
  target_type = "ip"
  vpc_id      = "vpc-0668d30a9cf84fc3e"
}

#########
resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "slyp.com.au"
    organization = "Slyp Pty Ltd"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.example.private_key_pem
  certificate_body = tls_self_signed_cert.example.cert_pem
}
########

resource "aws_lb_listener" "pi_alb_listener" {
  load_balancer_arn = aws_lb.pi_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pi_alb_tg.arn
  }
}

resource "aws_apigatewayv2_vpc_link" "pi_vpc_link" {
  name        = "pi-vpc-link"
  security_group_ids = ["sg-0330f3d740ffaeb69"]
  subnet_ids         = ["subnet-0884c63b66e350163", "subnet-059902d9ee58cc274", "subnet-06ec00f2a6788bff5"]
}

resource "aws_apigatewayv2_api" "pi_api" {
  name = "pi-poc-api-gw"
  description = "Proxy to handle requests to PanIntelligence API"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "pi_api_integration" {
  api_id = "${aws_apigatewayv2_api.pi_api.id}"
  integration_type   = "HTTP_PROXY"
  connection_id      = aws_apigatewayv2_vpc_link.pi_vpc_link.id
  connection_type    = "VPC_LINK"
  description        = "VPC integration"
  integration_method = "ANY"
  integration_uri    = aws_lb_listener.pi_alb_listener.arn
}

resource "aws_apigatewayv2_route" "pi_default_route" {
  api_id    = aws_apigatewayv2_api.pi_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.pi_api_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.pi_api.id
  name        = "$default"
  auto_deploy = true
}