variable "forward_mapping" {
  description = <<DESC
		A JSON encoded string that provides the forwardMapping dictionary
		for the ses-forwarding lambda function.
DESC

  type = "map"
}
