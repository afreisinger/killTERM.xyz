variable "region" {
  description = "AWS region(s) to place in"
  default     = "us-east-1"
}

variable "zone_name" {
  description = "DNS zone to operate on"
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

variable "reciever" {
  description = "SES smtp server to point the MX  record to"
  default     = "inbound-smtp.us-east-1.amazonaws.com"
}

variable "project" {
  description = "Project tag to add to all resources created"
}

variable "awscli" {
  description = "Absolute path to the `aws` command"
  default     = "/usr/local/bin/aws"
}
