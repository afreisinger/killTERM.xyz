output "complete_target" {
  depends_on = [
    "aws_ses_receipt_rule.ses_forwarding",
    "aws_route53_record.dkim_rec",
    "aws_route53_record.mx_zone_rec",
    "aws_iam_role_policy_attachment.ses_bounce_attach",
    "aws_iam_role_policy_attachment.lambda_log_attach",
    "aws_iam_role_policy_attachment.lambda_s3_attach",
    "aws_iam_role_policy_attachment.ses_send_attach",
    "aws_ses_receipt_rule.end_anchor",
  ]

  value = "${timestamp()}"
}

output "end_anchor" {
  value = "${aws_ses_receipt_rule.end_anchor.name}"
}
