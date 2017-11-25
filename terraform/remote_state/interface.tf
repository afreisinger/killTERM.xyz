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
