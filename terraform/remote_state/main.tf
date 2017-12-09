data "aws_caller_identity" "creator" {}

data "template_file" "s3_remote_state_policy" {
  template = "${file("${path.module}/s3_remote_state_policy.json.tpl")}"

  vars {
    prefix         = "${var.prefix}"
    aws_account_id = "${data.aws_caller_identity.creator.account_id}"
    uuid           = "${var.zone_uuid}"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"

  config {
    bucket         = "${aws_s3_bucket.remote_state.id}"
    key            = "terraform.tfstate"
    dynamodb_table = "${var.prefix}_terraform_statelock"
  }
}

resource "aws_dynamodb_table" "terraform_statelock" {
  name           = "${var.prefix}_terraform_statelock"
  hash_key       = "LockID"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name    = "${replace(var.prefix, ".", "_")}_terraform_statelock"
    Project = "${var.project}"
  }
}

resource "aws_s3_bucket_policy" "remote_state_policy" {
  bucket = "${aws_s3_bucket.remote_state.id}"
  policy = "${data.template_file.s3_remote_state_policy.rendered}"

  lifecycle {
    ignore_changes = ["policy"]
  }
}

resource "aws_s3_bucket" "remote_state" {
  bucket        = "${var.prefix}-${var.zone_uuid}-remote-state"
  force_destroy = "true"

  versioning {
    enabled = true
  }

  tags {
    Name    = "${var.prefix}-${var.zone_uuid}-remote-state"
    Project = "${var.project}"
  }
}
