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
`prevent_destroy` is set to *true* to on the remote-state S3 bucket and the bucket policy. This is to prevent accidentally losing your state file if something goes wrong in another part of the run.

This will cause `terraform destroy` to exit with a non-zero exit and report an error.  All the other resources will be destroyed but those two will remain. You can use `terraform state pull` to verify this.

The only solutions right now are to manually delete the bucket and its contents (the policy will be deleted automatically in this case) or edit the module and change the `lifecycle.prevent_destroy` attribute to *false*.

You should **strongly** consider converting to local state before doing this. See [Remote Backends](https://www.terraform.io/intro/getting-started/remote.html) for basic instructions on how to do this. *Note*: the S3 backend configuration is in the module itself, not at the root terraform directory.

See issues [#3116](https://github.com/hashicorp/terraform/issues/3116) and [#3874](https://github.com/hashicorp/terraform/issues/3874) for background on this problem. 
