variable "project" {
  description = "Project tag that will be applied to all resources created"
}

variable "zone_name" {
  description = "DNS zone name to create MX records in"
}

variable "region" {
  description = "AWS region to operate in"
  default     = "us-east-1"
}

## Uncomment this to enable remote state storage on S3
## You will need to run terraform init after making this change.
#terraform {
#  backend "s3" {}
#}

provider "aws" {
  region = "${var.region}"
}

module "remote_state" {
  source    = "remote_state"
  project   = "${var.project}"
  prefix    = "${var.zone_name}"
  zone_uuid = "${random_id.zone_uuid.b64_url}"
}

module "ses_forwarding" {
  source    = "ses_forwarding"
  project   = "${var.project}"
  region    = "${var.region}"
  zone_name = "${var.zone_name}"
  zone_uuid = "${random_id.zone_uuid.b64_url}"
}

resource "random_id" "zone_uuid" {
  keepers = {
    id = "${var.zone_name}"
  }

  byte_length = "8"
}

# Terraform is very picky about the format of tfvars files.
resource "local_file" "remote_state_tfvars" {
  content  = "${data.template_file.remote_state_config.rendered}"
  filename = "remote_state.tfvars"
}

data "template_file" "remote_state_config" {
  template = <<STATE_CONFIG
bucket="$${bucket_id}"
key="terraform.tfstate"
dynamodb_table="$${table}"
STATE_CONFIG

  vars {
    bucket_id = "${module.remote_state.bucket_id}"
    key       = "terraform.tfstate"
    table     = "${module.remote_state.dynamodb_table}"
  }
}
