variable "prefix" {
  description = "Prefix for s3 bucket to use for remote state"
}

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

terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "remote_state" {
  source  = "remote_state"
  project = "${var.project}"
  prefix  = "${var.prefix}"
}

module "ses_forwarding" {
  source    = "ses_forwarding"
  project   = "${var.project}"
  region    = "${var.region}"
  zone_name = "${var.zone_name}"
}
