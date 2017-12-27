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
    "random_id.zone_uuid",
  ]
}

module "ses_forwarding" {
  source = "../../modules/ses_forwarding"

  zone_apex       = "${var.zone_apex}"
  zone_name       = "${var.environment}.${var.zone_apex}"
  zone_uuid       = "${random_id.zone_uuid.b64_url}"
  region          = "${var.region}"
  project         = "${var.project}"
  environment     = "${var.environment}"
  anchor          = "${data.terraform_remote_state.email_prod.end_anchor}"
  forward_mapping = "${var.forward_mapping}"
  lambda_path     = "${path.root}/lambda"
  rule_set_name   = "${data.terraform_remote_state.email_prod.ses_active_rule_set}"
}

output "end_anchor" {
  value = "${module.ses_forwarding.end_anchor}"
}
