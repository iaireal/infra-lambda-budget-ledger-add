# The Lambda function budget-ledger-add and everything that belongs only to
# it: its role and its log group.

locals {
  function_name = "budget-ledger-add"

  # The release downloaded by `task download`. This repository never builds
  # the function; it deploys a published release of lambda-budget-ledger-add.
  package = "${path.module}/artifacts/${var.function_version}/bootstrap.zip"
}

# --- Logs -------------------------------------------------------------------

# Created here, not by Lambda, so the retention is set and Terraform removes
# the logs together with the function.
resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}

# --- Role -------------------------------------------------------------------

# Only the Lambda service may use this role.
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "function" {
  name               = "${local.function_name}-lambda"
  description        = "Role the ${local.function_name} Lambda function runs with."
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# The function may write to its own log group and do nothing else.
data "aws_iam_policy_document" "logs" {
  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.function.arn}:*"]
  }
}

resource "aws_iam_role_policy" "logs" {
  name   = "write-own-logs"
  role   = aws_iam_role.function.id
  policy = data.aws_iam_policy_document.logs.json
}

# --- Function ---------------------------------------------------------------

resource "aws_lambda_function" "function" {
  function_name = local.function_name
  description   = "Adds two numbers with the budget-ledger library. Release ${var.function_version}."
  role          = aws_iam_role.function.arn

  # The release is a Rust program built for Linux arm64. Lambda runs it on
  # its plain Linux runtime, which starts the file named `bootstrap`.
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  handler       = "bootstrap"

  filename         = local.package
  source_code_hash = filebase64sha256(local.package)

  memory_size = 128
  timeout     = 3

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.function.name
  }

  tags = {
    FunctionVersion = var.function_version
  }

  depends_on = [aws_iam_role_policy.logs]
}
