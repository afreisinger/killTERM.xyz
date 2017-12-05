# Remote State for terraform
The `remote_state` module creates an S3 bucket to store terraform state remotely. It also provides locking via DynamoDB to prevent contention during concurrent runs.

## Variables

### region (optional)
Defines what AWS region to operate in. Defaults to `us-east-1`.

### prefix
Defines a prefix to prepend to the S3 bucket to be created and used for remote state storage. ex: prefix="foo.xyz" would create a bucket named `foo.xyz-remote-state`. It is also used as part of the name for the DynamoDB database that will be created for locking.

### project
See the top-level variable notes in the [root terraform directory](../README.md).

## Remote State Bucket Destruction
Terraform will destroy the remote state bucket on `terraform destroy`. This option is not reversible.  If an error occurs you can find the last known state in *errored.tfstate* locally.

You should **strongly** consider converting to local state before doing this. See [Remote Backends](https://www.terraform.io/intro/getting-started/remote.html) for basic instructions on how to do this. *Note*: the S3 backend configuration is in the module itself, not at the root terraform directory.

If you choose not to change to a local state backend terraform will complete the destroy but exit with an error status. You can check *errored.tfstate*

See issues [#3116](https://github.com/hashicorp/terraform/issues/3116) and [#3874](https://github.com/hashicorp/terraform/issues/3874) for background on this problem. 
