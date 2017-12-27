variable "project" {
  description = "Project tag that will be applied to all resources created"
}

variable "zone_apex" {
  description = "Root DNS zone to create records and subdomains in"
}

variable "region" {
  description = "AWS region to operate in"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment we are operating in"
}

variable "bucket" {
  description = "S3 bucket to hold remote state"
}

variable "dynamodb_table" {
  description = "DynamoDB table for remote state locking"
}

terraform {
  backend "s3" {
    key     = "terraform.tfstate"
    encrypt = "true"
    acl     = "private"
  }
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.6"
}

provider "random" {
  version = "~> 1.1"
}

data "terraform_remote_state" "email_prod" {
  backend = "s3"

  config {
    key            = "env:/email-prod/terraform.tfstate"
    bucket         = "${var.bucket}"
    dynamodb_table = "${var.dynamodb_table}"
  }
}

data "terraform_remote_state" "email_staging" {
  backend = "s3"

  config {
    key            = "env:/email-staging/terraform.tfstate"
    bucket         = "${var.bucket}"
    dynamodb_table = "${var.dynamodb_table}"
  }
}

data "terraform_remote_state" "email_uat" {
  backend = "s3"

  config {
    key            = "env:/email-uat/terraform.tfstate"
    bucket         = "${var.bucket}"
    dynamodb_table = "${var.dynamodb_table}"
  }
}

resource "random_id" "zone_uuid" {
  keepers = {
    id = "${var.environment}.${var.zone_apex}"
  }

  byte_length = "8"
}

resource "null_resource" "canary" {
  triggers {
    dummy = "${random_id.zone_uuid.Only_targets_not_plain_apply}"
  }
}
