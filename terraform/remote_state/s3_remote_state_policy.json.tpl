{
  "Version": "2012-10-17",
  "Id": "${prefix}RemoteState",
  "Statement": [
    {
      "Sid": "AllowAccountRead",
      "Effect": "Allow",
      "Principal": { "AWS": "${aws_account_id}" },
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "arn:aws:s3:::${prefix}-${uuid}-remote-state/*",
        "arn:aws:s3:::${prefix}-${uuid}-remote-state"
      ]
    }
  ]
}
