
resource "aws_apigatewayv2_domain_name" "pi_poc_domain" {
  domain_name = "dashboards.data.team-slyp.com.au"

  domain_name_configuration {
    certificate_arn = "arn:aws:acm:ap-southeast-2:824763547294:certificate/98f4d37e-35b0-4c18-94bc-b80c249abacb"
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "pi_dns_record" {
  name    = aws_apigatewayv2_domain_name.pi_poc_domain.domain_name
  type    = "A"
  zone_id = "Z00505302C72GZTJUJ2J1"

  alias {
    name                   = aws_apigatewayv2_domain_name.pi_poc_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.pi_poc_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

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

resource "aws_lb_target_group" "pi_alb_tomcat_tg" {
  port        = 8224
  protocol    = "HTTPS"
  vpc_id      = "vpc-0668d30a9cf84fc3e"
}

resource "aws_lb_target_group_attachment" "pi_alb_tomcat_tg_att" {
  target_group_arn = aws_lb_target_group.pi_alb_tomcat_tg.arn
  target_id        = "i-0545232137aa0a9de"
  port             = 8224
}

resource "aws_lb_listener" "pi_alb_tomcat_listener" {
  load_balancer_arn = aws_lb.pi_alb.arn
  port              = "8224"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-2:824763547294:certificate/98f4d37e-35b0-4c18-94bc-b80c249abacb"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pi_alb_tomcat_tg.arn
  }
}

resource "aws_lb_target_group" "pi_alb_http_tg" {
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0668d30a9cf84fc3e"
}

resource "aws_lb_target_group_attachment" "pi_alb_http_tg_att" {
  target_group_arn = aws_lb_target_group.pi_alb_http_tg.arn
  target_id        = "i-0545232137aa0a9de"
  port             = 80
}

resource "aws_lb_listener" "pi_alb_http_listener" {
  load_balancer_arn = aws_lb.pi_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pi_alb_http_tg.arn
  }
}

resource "aws_lb_target_group" "pi_alb_tg" {
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = "vpc-0668d30a9cf84fc3e"
}

resource "aws_lb_target_group_attachment" "pi_alb_tg_att" {
  target_group_arn = aws_lb_target_group.pi_alb_tg.arn
  target_id        = "i-0545232137aa0a9de"
  port             = 443
}

resource "aws_lb_listener" "pi_alb_listener" {
  load_balancer_arn = aws_lb.pi_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-southeast-2:824763547294:certificate/98f4d37e-35b0-4c18-94bc-b80c249abacb"
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

resource "aws_apigatewayv2_api_mapping" "friendly_domain_mapping" {
  api_id      = aws_apigatewayv2_api.pi_api.id
  domain_name = aws_apigatewayv2_domain_name.pi_poc_domain.id
  stage       = aws_apigatewayv2_stage.default_stage.id
}