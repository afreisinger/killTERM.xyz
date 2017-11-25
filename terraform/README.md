# Terraform configurations for killTERM.xyz

This Terraform configuration set will instantiate and destroy AWS infrastructure components for the killTERM.xyz example environment.

This is the place you ***WILL*** incur AWS charges if you create resources.

## Terraform variables

At the top level configuration directory (this directory) 3 variables are required to be set:


###

### zone_name

The Route53 zone that DNS entries will be created in for SES DKIM and SPF records.

The Route53 zone must be manually created prior to applying these commands with at least the SOA and NS records populated.

If you register your domain through AWS a zone will be automatically created for you with the required fields pre-populated.

If you prefer to use a different registrar see [Migrating DNS Service for an Existing Domain to Amazon Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html).

### project
The value for a tag with the key `Project`, this is used to help track costs and verify cleanup after a destroy. All resources created will have this tag attached if possible.

### prefix
A prefix to prepend to the S3 bucket that will be used for storing terraform's remote state bucket. This will also be used for the DynamoDB state lock database.

### region (optional)

Specify the AWS region to operate in. Defaults to `us-east-1`. This has not been tested in any other region so please provide feedback on other regions if you try them there.

## Specifying Variables
The above variables may all be defined on the command line with the `-var "<var>=<value>"`, in a file specified with `-var-file=<var_file_name>` or in a file named `terraform.tfvars` in this directory.

If you use the terraform.tfvars file you should ensure that it is added to `.gitignore` to avoid possibly leaking sensitive information in source control.

A sample terraform.tfvars file is named [terraform.tfvars](terraform.tfvars) in this directory.

## Terraform modules
Two modules are used to do most of the real work.

### remote_state
The `remote_state` module stores the terraform.tfstate file in an S3 bucket to enable multiple people to work with the terraform configurations concurrently.

It also creates a small DynamoDB database to ensure state consistency during concurrent runs.

See the remote_state [README](remote_state/README.md) for more information on this module.

### ses_forwarding
The `ses_forwarding` module sets up an SES and lambda based SMTP receiver that can forward emails to your domain to another provider like gmail without having to pay for gmail for domains. It's not the greatest solution but it's cheap and easy.

This module requires some additional configuration. See the ses_forwarding [README](ses_forwarding/README.md) for more information on this module.
