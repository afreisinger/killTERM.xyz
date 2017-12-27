variable "region" {
  description = "AWS region(s) to place in"
  default     = "us-east-1"
}

variable "zone_apex" {
  description = "DNS zone to operate on"
}

variable "zone_name" {
  description = "FQDN of subdomain"
}

variable "zone_uuid" {
  description = "Generated UUID for global namespaces"
}

variable "reciever_map" {
  description = "Map of reigon: smtp servers to recieve mail on"
  type        = "map"

  default = {
    us-east-1 = "inbound-smtp.us-east-1.amazonaws.com"
    us-west-1 = "inbound-smtp.us-west-1..amazonaws.com"
    eu-wast-1 = "inbound smtp.eu-west-1.amazonaws.com"
  }
}

# If empty the above region map will be used.
variable "reciever" {
  description = "SES smtp server to point the MX record to"
  default     = ""
}

variable "project" {
  description = "Project tag to add to all resources created"
}

variable "awscli" {
  description = "Absolute path to the `aws` command"
  default     = "/usr/local/bin/aws"
}

variable "environment" {
  description = "Environment to operate on"
}

variable "lambda_func_name" {
  description = "Name of the lambda function to call on SES delivery"
  default     = "ses-forwarding"
}

variable "anchor" {
  description = "Receipt rule set to being placing this environment's rules after"
}

variable "lambda_path" {
  description = "Path to lambda package to archive and upload"
  default     = "false"
}

variable "forward_mapping" {
  description = "A JSON dict to pass into the ses-forwarding forwardMapping configuration override"
  type        = "map"
}

variable "rule_set_name" {
  description = "The active rule set to attach SES receipt rules to"
}
