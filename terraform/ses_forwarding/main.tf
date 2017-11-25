/*
 * ses_forward.tf
 * Sets up a Route53 Zone and SES email forwarding for our domain.
 * The Route53 zone must already exist in the account and have
 * the corect NS records set.
 */

data "aws_route53_zone" "zone" {
  name = "${var.zone_name}"
}

resource "aws_route53_record" "mx_zone_rec" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "mail.${data.aws_route53_zone.zone.name}"
  type    = "MX"
  ttl     = "60"
  records = ["10 ${length(var.reciever) > 0 ? var.reciever : lookup(var.reciever_map, var.region)}"]
}

# aws_ses_domain_identity indiscriminately adds a . even if it's already there
resource "aws_ses_domain_identity" "ses_domain_id" {
  domain = "${replace(data.aws_route53_zone.zone.name, "/\\.$/", "")}"
}

resource "aws_route53_record" "ses_verification_rec" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "_amazonses.${data.aws_route53_zone.zone.name}"
  type    = "TXT"
  ttl     = "60"
  records = ["${aws_ses_domain_identity.ses_domain_id.verification_token}"]
}

# aws_ses_domain_dkim indiscriminately adds a . even if it's already there
resource "aws_ses_domain_dkim" "dkim_keys" {
  domain = "${replace(data.aws_route53_zone.zone.name, "/\\.$/", "")}"
}

resource "aws_route53_record" "dkim_rec" {
  count   = 3
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}._domainkey.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}.dkim.amazonses.com."]
}
