locals {
  bucket_name    = "${var.zone_uuid}-${var.zone_name}-ses-emails"
  lambda_func    = "${replace(var.zone_name, ".", "_")}-${var.lambda_func_name}"
  lambda_path    = "${var.lambda_path == "false" ? "${path.module}/lambda" : var.lambda_path}"
  lambda_key_arn = "arn:aws:kms:${var.region}:${data.aws_caller_identity.creator.account_id}:key/${data.aws_kms_alias.lambda_key_alias.target_key_id}"
}

provider "archive" {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 1.0"
}

data "aws_caller_identity" "creator" {}

data "aws_route53_zone" "zone" {
  name = "${var.zone_apex}"
}

data "aws_kms_alias" "lambda_key_alias" {
  name = "alias/aws/lambda"
}

resource "aws_route53_record" "mx_zone_rec" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "${var.zone_name}"
  type    = "MX"
  ttl     = "60"
  records = ["10 ${length(var.reciever) > 0 ? var.reciever : lookup(var.reciever_map, var.region)}"]

  lifecycle {
    create_before_destroy = "false"
  }
}

resource "aws_ses_domain_identity" "ses_domain_id" {
  domain = "${var.zone_name}"
}

resource "aws_route53_record" "ses_verification_rec" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "_amazonses.${var.zone_name}"
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
  name    = "${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}._domainkey.${var.zone_name}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${element(aws_ses_domain_dkim.dkim_keys.dkim_tokens, count.index)}.dkim.amazonses.com."]

  depends_on = [
    "aws_ses_domain_dkim.dkim_keys",
  ]
}

resource "aws_s3_bucket" "ses_emails" {
  bucket        = "${local.bucket_name}"
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
    Name        = "${local.bucket_name}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
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
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
}

resource "aws_lambda_function" "ses_forwarding" {
  filename      = "${data.archive_file.ses_forwarder_zip.output_path}"
  function_name = "${local.lambda_func}"
  handler       = "index.handler"
  role          = "${aws_iam_role.ses_forwarding_role.arn}"
  kms_key_arn   = "${local.lambda_key_arn}"

  environment {
    variables = {
      S3_BUCKET       = "${local.bucket_name}"
      FORWARD_MAPPING = "${jsonencode(var.forward_mapping)}"
    }
  }

  source_code_hash = "${data.archive_file.ses_forwarder_zip.output_base64sha256}"

  runtime = "nodejs6.10"
  timeout = "10"

  tags {
    Name        = "${local.lambda_func}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "null_resource" "npm" {
  triggers {
    index_js     = "${base64sha256(file("${local.lambda_path}/index.js"))}"
    package_json = "${base64sha256(file("${local.lambda_path}/package.json"))}"
  }

  provisioner "local-exec" {
    command = "pushd ${local.lambda_path} && npm install && popd"
  }
}

data "archive_file" "ses_forwarder_zip" {
  type        = "zip"
  output_path = "${path.root}/${var.environment}-ses-forwarding.zip"
  source_dir  = "${local.lambda_path}"

  depends_on = ["null_resource.npm"]
}

# Aside from the assume_role_policy document execution permissions
# are defined and attached in their respective *_perms.tf
resource "aws_iam_role" "ses_forwarding_role" {
  description           = "AssumeRole and Execution permissions for the ses-forwarder lambda function"
  name                  = "${var.environment}-SESLambdaForwarding"
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
