variable "region" {
  description = "AWS region to operate in"
  default     = "us-east-1"
}

variable "prefix" {
  description = "S3 prefix to use"
}

variable "project" {
  description = "Project tag to use for all resources created"
}

variable "zone_uuid" {
  description = "Generated UUID for global namespaces"
}

output "bucket_id" {
  value = "${aws_s3_bucket.remote_state.id}"
}

output "dynamodb_table" {
  value = "${var.prefix}_terraform_statelock"
}
