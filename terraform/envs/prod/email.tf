variable "forward_mapping" {
  description = <<DESC
		A JSON encoded string that provides the forwardMapping dictionary
		for the ses-forwarding lambda function.
DESC

  type = "map"
}

resource "null_resource" "email" {
  triggers {
    complete = "${module.ses_forwarding.complete_target}"
  }

  depends_on = [
    "aws_ses_active_receipt_rule_set.active_rule_set",
  ]
}

# prod diff
resource "aws_ses_receipt_rule_set" "ses_forwarding" {
  rule_set_name = "ses-forwarding"
}

resource "aws_ses_active_receipt_rule_set" "active_rule_set" {
  rule_set_name = "${aws_ses_receipt_rule_set.ses_forwarding.rule_set_name}"
}

resource "aws_ses_receipt_rule" "root_anchor" {
  name          = "root-anchor"
  enabled       = "false"
  scan_enabled  = "false"
  tls_policy    = "Require"
  rule_set_name = "${aws_ses_receipt_rule_set.ses_forwarding.rule_set_name}"

  depends_on = [
    "random_id.zone_uuid",
  ]
}

# end diff
module "ses_forwarding" {
  source = "../../modules/ses_forwarding"

  zone_apex       = "${var.zone_apex}"
  zone_name       = "${var.zone_apex}"
  zone_uuid       = "${random_id.zone_uuid.b64_url}"
  region          = "${var.region}"
  project         = "${var.project}"
  environment     = "${var.environment}"
  anchor          = "${aws_ses_receipt_rule.root_anchor.name}"
  forward_mapping = "${var.forward_mapping}"
  lambda_path     = "${path.root}/lambda"

  # prod diff
  rule_set_name = "${aws_ses_receipt_rule_set.ses_forwarding.rule_set_name}"

  # end diff
}

# prod diff
output "ses_active_rule_set" {
  value = "${aws_ses_receipt_rule_set.ses_forwarding.rule_set_name}"
}

# end diff

output "end_anchor" {
  value = "${module.ses_forwarding.end_anchor}"
}
