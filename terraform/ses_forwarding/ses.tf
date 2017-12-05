resource "aws_ses_receipt_rule_set" "ses_forwarding" {
  rule_set_name = "ses-forwarding"
}

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
  name          = "bounce-noreply"
  rule_set_name = "ses-forwarding"
  recipients    = ["noreply@${var.zone_name}"]
  enabled       = "true"
  scan_enabled  = "false"

  depends_on = [
    "aws_ses_receipt_rule_set.ses_forwarding",
    "null_resource.wait_for_ses_validation",
  ]

  bounce_action {
    message         = "This is an unattended mailbox, your message has been discarded."
    sender          = "postmaster@${var.zone_name}"
    smtp_reply_code = "550"
    status_code     = "5.5.1"
    position        = "1"
  }
}

resource "aws_ses_receipt_rule" "ses_forwarding" {
  name          = "ses-forwarding"
  after         = "bounce-noreply"
  enabled       = "true"
  scan_enabled  = "true"
  rule_set_name = "ses-forwarding"

  depends_on = [
    "aws_ses_receipt_rule_set.ses_forwarding",
    "aws_route53_record.ses_verification_rec",
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
}

resource "aws_ses_active_receipt_rule_set" "active_ruleset" {
  rule_set_name = "ses-forwarding"
  depends_on    = ["aws_ses_receipt_rule_set.ses_forwarding"]
}
