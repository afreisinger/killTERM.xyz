resource "null_resource" "wait_for_ses_validation" {
  triggers {
    token = "${aws_ses_domain_identity.ses_domain_id.verification_token}"
  }

  provisioner "local-exec" {
    # line continuation is messed up with HCL and \
    command = <<SCRIPT
seconds=0
while [ $seconds -lt 300 ]; do
    ${var.awscli} ses get-identity-verification-attributes --identities ${var.zone_name} --output text | cut -f2 | grep -q Success && break || seconds=$(($seconds + 30)); sleep 30
done
if [ $seconds -ge 300 ]; then
  echo Waited too long, aborting.
  exit 1
fi
SCRIPT

    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = ["aws_route53_record.ses_verification_rec"]
}

resource "aws_ses_receipt_rule" "ses_noreply" {
  name          = "${var.environment}-bounce-noreply"
  rule_set_name = "${var.rule_set_name}"
  after         = "${aws_ses_receipt_rule.begin_anchor.name}"

  recipients = [
    "noreply@${var.zone_name}",
  ]

  enabled      = "true"
  scan_enabled = "false"

  depends_on = [
    "null_resource.wait_for_ses_validation",
  ]

  bounce_action {
    message         = "This is an unattended mailbox, your message has been discarded."
    sender          = "postmaster@${var.zone_name}"
    smtp_reply_code = "550"
    status_code     = "5.5.1"
    position        = "1"
  }

  stop_action {
    scope    = "RuleSet"
    position = "2"
  }
}

resource "aws_ses_receipt_rule" "ses_forwarding" {
  name          = "${var.environment}-ses-forwarding"
  after         = "${aws_ses_receipt_rule.ses_noreply.name}"
  enabled       = "true"
  scan_enabled  = "true"
  tls_policy    = "Require"
  rule_set_name = "${var.rule_set_name}"

  recipients = [
    "${var.zone_name}",
  ]

  s3_action {
    bucket_name       = "${aws_s3_bucket.ses_emails.id}"
    object_key_prefix = "emails/"
    position          = "1"
  }

  lambda_action {
    function_arn    = "${aws_lambda_function.ses_forwarding.arn}"
    invocation_type = "Event"
    position        = "2"
  }

  depends_on = [
    "aws_lambda_permission.ses_forwarding_function_policy",
  ]
}

resource "aws_ses_receipt_rule" "begin_anchor" {
  name          = "${var.zone_name}-begin-anchor"
  enabled       = "false"
  scan_enabled  = "false"
  tls_policy    = "Require"
  rule_set_name = "${var.rule_set_name}"
  after         = "${var.anchor}"

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_ses_receipt_rule" "end_anchor" {
  name          = "${var.zone_name}-end-anchor"
  enabled       = "false"
  scan_enabled  = "false"
  tls_policy    = "Require"
  rule_set_name = "${var.rule_set_name}"
  after         = "${aws_ses_receipt_rule.ses_forwarding.name}"

  lifecycle {
    create_before_destroy = "true"
  }
}
