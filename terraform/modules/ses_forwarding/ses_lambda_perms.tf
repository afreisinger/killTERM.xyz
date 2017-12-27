/*
 * Permissions and policies to allow the forwarding specific bits.
 */

# Attach to the role defined in basic_lambda_perms.tf
resource "aws_iam_role_policy_attachment" "ses_send_attach" {
  role       = "${aws_iam_role.ses_forwarding_role.name}"
  policy_arn = "${aws_iam_policy.ses_send_email_pol.arn}"
}

# Policy to allow sending raw email
resource "aws_iam_policy" "ses_send_email_pol" {
  description = "Grant the SESSendRawEmail permission"
  name        = "${var.environment}-SESSendRawEmail"
  policy      = "${data.aws_iam_policy_document.ses_send_email_doc.json}"

  lifecycle {
    create_before_destroy = "true"
  }
}

data "aws_iam_policy_document" "ses_send_email_doc" {
  policy_id = "SESSendRaw"

  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_lambda_permission" "ses_forwarding_function_policy" {
  statement_id   = "AllowExecutionFromSES"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.ses_forwarding.arn}"
  principal      = "ses.amazonaws.com"
  source_account = "${data.aws_caller_identity.creator.account_id}"
}
