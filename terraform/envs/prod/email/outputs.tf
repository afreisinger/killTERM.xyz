# prod diff
output "ses_active_rule_set" {
  value = "${aws_ses_receipt_rule_set.ses_forwarding.rule_set_name}"
}

# end diff

output "end_anchor" {
  value = "${module.ses_forwarding.end_anchor}"
}
