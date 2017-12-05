variable "lambda_func_name" {
  default = "ses-forwarding"
}

data "aws_caller_identity" "creator" {}

data "aws_route53_zone" "zone" {
  name = "${var.zone_name}"
}

resource "aws_route53_record" "mx_zone_rec" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${data.aws_route53_zone.zone.name}"
  type    = "MX"
  ttl     = "60"
  records = ["10 ${length(var.reciever) > 0 ? var.reciever : lookup(var.reciever_map, var.region)}"]

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_ses_domain_identity" "ses_domain_id" {
  domain = "${var.zone_name}"
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
  domain = "${aws_ses_domain_identity.ses_domain_id.domain}"
}

resource "aws_route53_record" "dkim_rec" {
  count   = 3
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}._domainkey.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}.dkim.amazonses.com."]
}

resource "aws_s3_bucket" "ses_emails" {
  bucket        = "${var.zone_name}-ses-emails"
  policy        = "${data.aws_iam_policy_document.ses_s3_action_doc.json}"
  acl           = "private"
  force_destroy = "true"

  lifecycle_rule {
    id      = "autopurge"
    enabled = "true"

    expiration {
      days = 10
    }
  }

  versioning {
    enabled = "false"
  }

  tags {
    Name    = "${var.zone_name}-ses-emails"
    Project = "${var.project}"
  }

  lifecycle {
    prevent_destroy = "false"
  }
}

# This is the bucket policy document, not an IAM policy document
data "aws_iam_policy_document" "ses_s3_action_doc" {
  policy_id = "SESActionS3"

  statement {
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.zone_name}-ses-emails/*"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
}

resource "aws_lambda_function" "ses_forwarding" {
  filename      = "${path.module}/ses-forwarding.zip"
  function_name = "${var.lambda_func_name}"
  handler       = "index.handler"
  role          = "${aws_iam_role.ses_forwarding_role.arn}"

  source_code_hash = "${base64sha256(file("${path.module}/ses-forwarding.zip"))}"

  runtime = "nodejs6.10"
  timeout = "10"

  depends_on = ["null_resource.npm"]
}

resource "null_resource" "npm" {
  triggers {
    index_js     = "${base64sha256(file("${path.module}/lambda/index.js"))}"
    package_json = "${base64sha256(file("${path.module}/lambda/package.json"))}"
  }

  provisioner "local-exec" {
    command     = "rm -f ${path.module}/ses-forwarding.zip && pushd ${path.module}/lambda && npm install && zip -r -q ${path.module}/ses-forwarding.zip . && popd"
    interpreter = ["/bin/bash", "-c"]
  }
}

# Aside from the assume_role_policy document execution permissions
# are defined and attached in their respective *_perms.tf
resource "aws_iam_role" "ses_forwarding_role" {
  description           = "AssumeRole and Execution permissions for the ses-forwarder lambda function"
  name                  = "SESLambdaForwarding"
  path                  = "/service-role/"
  assume_role_policy    = "${data.aws_iam_policy_document.assume_lambda_role_doc.json}"
  force_detach_policies = "true"
}

# The assume role policy document referenced above.
# This lets us operate on behalf of the lambda service, it is not a standard
# IAM policy document.
data "aws_iam_policy_document" "assume_lambda_role_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
