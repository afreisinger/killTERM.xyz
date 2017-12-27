/*
 * IAM Permissions for aws-ses-lambda-forwarding.
 * These can be confusing if you've never set up a lambda function manually
 * The definitions are top down with an attempt at logical grouping
 */

resource "aws_iam_role_policy_attachment" "ses_bounce_attach" {
  role       = "${aws_iam_role.ses_forwarding_role.name}"
  policy_arn = "${aws_iam_policy.ses_send_bounce_pol.arn}"
}

resource "aws_iam_role_policy_attachment" "lambda_log_attach" {
  role       = "${aws_iam_role.ses_forwarding_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging_pol.arn}"
}

# Allows SES triggered events to send bounces if the lambda function gives up.
resource "aws_iam_policy" "ses_send_bounce_pol" {
  name   = "${var.environment}-SESSendBounce"
  path   = "/service-role/"
  policy = "${data.aws_iam_policy_document.ses_send_bounce_doc.json}"

  lifecycle {
    create_before_destroy = "true"
  }
}

data "aws_iam_policy_document" "ses_send_bounce_doc" {
  policy_id = "SESSendBounce"

  statement {
    actions   = ["ses:SendBounce"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_logging_pol" {
  name   = "${var.environment}-LambdaSESForwardingLogs"
  path   = "/service-role/"
  policy = "${data.aws_iam_policy_document.lambda_logs_doc.json}"

  lifecycle {
    create_before_destroy = "true"
  }
}

# Allow our lambda function to create it's log group and streams
data "aws_iam_policy_document" "lambda_logs_doc" {
  policy_id = "SESForwardingLambdaLogs"

  statement {
    actions = ["logs:CreateLogGroup"]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.creator.account_id}:*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.creator.account_id}:log-group:/aws/lambda/${local.lambda_func}:*",
    ]
  }
}
