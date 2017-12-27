/*
 * IAM and bucket policies for the S3 bucket storing emails
 */

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = "${aws_iam_role.ses_forwarding_role.name}"
  policy_arn = "${aws_iam_policy.lambda_s3_pol.arn}"
}

resource "aws_iam_policy" "lambda_s3_pol" {
  description = "Allow RW access for the ses-emails bucket"
  name        = "LambdaSESForwardingS3RW"
  policy      = "${data.aws_iam_policy_document.lambda_s3_rw_doc.json}"
}

data "aws_iam_policy_document" "lambda_s3_rw_doc" {
  policy_id = "LambdaSESForwardingS3RW"

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.ses_emails.arn}/*"]
  }
}
