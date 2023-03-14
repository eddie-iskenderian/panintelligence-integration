# resource "aws_api_gateway_authorizer" "pi_myslyp_authorizer" {
#   name                   = "pi-myslyp-authorizer"
#   rest_api_id            = "${aws_apigatewayv2_api.pi_api.id}"
#   authorizer_uri         = aws_lambda_function.pi_authorizer_lambda.invoke_arn
#   authorizer_credentials = aws_iam_role.pi_authorizer_invoke_role.arn
# }

# data "aws_iam_policy_document" "pi_authorizer_assume_document" {
#   statement {
#     effect = "Allow"

#     principals {
#       type       = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }

#     actions = ["sts:AssumeRole"]
#   }
# }

# resource "aws_iam_role" "pi_authorizer_invoke_role" {
#   name               = "pi-authorizer-invoke-role"
#   path               = "/"
#   assume_role_policy = data.aws_iam_policy_document.pi_authorizer_assume_document.json
# }

# data "aws_iam_policy_document" "pi_authorizer_invoke_document" {
#   statement {
#     effect    = "Allow"
#     actions   = ["lambda:InvokeFunction"]
#     resources = [aws_lambda_function.pi_authorizer_lambda.arn]
#   }
# }

# resource "aws_iam_role_policy" "pi_authorizer_invoke_policy" {
#   name   = "auth-invoke-policy"
#   role   = aws_iam_role.pi_authorizer_invoke_role.id
#   policy = data.aws_iam_policy_document.pi_authorizer_invoke_document.json
# }

data "aws_iam_policy_document" "pi_authorizer_lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pi_authorizer_lambda_role" {
  name               = "pi-auth-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.pi_authorizer_lambda_assume_role.json
  # Add permissions for secrets manager and cloud watch
}

resource "aws_lambda_function" "pi_authorizer_lambda" {
  filename      = "${var.base_dir}/build/pi-auth-lambda.zip"
  function_name = "pi-auth-lambda"
  role          = aws_iam_role.pi_authorizer_lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  source_code_hash = filebase64sha256("${var.base_dir}/build/pi-auth-lambda.zip")
}