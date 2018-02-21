# Terraform configurations for killTERM.xyz

This Terraform configuration set will instantiate and destroy AWS infrastructure components for the killTERM.xyz example environment.

This is the place you ***WILL*** incur AWS charges if you create resources.

## Requirements
### Software

* [Terraform >= 1.11.0](https://www.terraform.io/intro/getting-started/install.html)
* [jq >= 1.5](https://stedolan.github.io/jq/download/)
* [AWS CLI >= 1.11.120](https://github.com/aws/aws-cli)
* A *zip* command line utility for creating .zip files

## Prerequisite Setup
### AWS Account
You must have already created and AWS account. It is strongly suggested you create an IAM user and add them to the root group as well.

Everything assumes you have configured the AWS CLI tools as described in the [AWS Command Line Interface User Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

You must have already registered and created at least one [public Hosted Zone with Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html).

It should be possible to modify the configuration here to use entirely Private Route 53 Hosted zones as well as reusable delegation sets as well but is not implemented currently (PR's welcome).

Keep in mind that [charges for Route 53 Hosted Zones](https://aws.amazon.com/route53/pricing/) are not pro-rated. You will incur the full monthly cost if a zone exists for more than 12 hours even in accounts that qualify for the free tier. **It is your responsibility to destroy the hosted zones created within 12 hours if you do not wish to incur these charges**.

## First time initialization
You should only have to do this once.

1) Bootstrap the remote state backend for S3 storage:
```
aws cloudformation create-stack --stack-name <YOUR-STACK-NAME>
 --template-body file://`pwd`/cf-bootstrap.yaml --capabilities CAPABILITY_IAM --tags "Key=Project,Value=<YOUR-PROJECT-TAG>"
```

This creates the S3 bucket for storing remote state and a DynamoDB for locking. It should fall completely within the Free Tier and cost nothing.

2) Wait for stack creation to complete (should take less than a minute):
```
aws cloudformation wait stack-create-complete --stack-name <YOUR-STACK-NAME>
```

3) Generate the tfvars for our backend initialization:
```
aws cloudformation --output=json describe-stacks | jq '.Stacks[] | select(.StackName == "<YOUR-STACK-NAME>") | .Outputs | map(.OutputKey = (.OutputKey | sub("dynamodbtable"; "dynamodb_table"))) | map({(.OutputKey): .OutputValue}) | add' > backend-config.tfvars.json
```

This extracts the unique resource names created by the CloudFormation template and places them in a JSON tfvars file to be read by Terraform later.

# Terraform Organization
## Layout
This is a bit in-flux but based loosely on the [Terraservices](https://www.slideshare.net/opencredo/hashidays-london-2017-evolving-your-infrastructure-with-terraform-by-nicki-watt) model using the [*workspace*](https://www.terraform.io/docs/state/workspaces.html) feature introduced in Terraform 0.10. The directory layout looks like this:

```
/
├── README.md
├── backend-config.tfvars.json
├── cf-bootstrap.yaml
├── main.tf
├── terraform.tfvars
├── envs
│   ├── prod
│   │   ├── 00-backend-config.auto.tfvars.json -> ../../backend-config.tfvars.json
│   │   ├── 00-main.tf -> ../../main.tf
│   │   ├── 00-terraform.auto.tfvars -> ../../terraform.tfvars
│   │   ├── email.tf
│   │   ├── lambda
│   │   ├── lambda
│   │   │   ├── index.js
│   │   │   ├── node_modules
│   │   │   └── package.json
│   │   ├── terraform.tfvars
│   │   └── terraform.tfvars.json
│   ├── staging
│   │   └── ...
│   └── uat
│       └── ..

└── modules
    └── ses_forwarding
```

The `envs/<env>/` directories contain configuration for a specific environment and is it's own TERRAFORM_ROOT.

The `00-...` symlinks link back to the top level directory (this one) where items common to all environments are stored. These are simply to reduce boilerplate environment setup and bring variables and cross-environment data into the current environment's namespace.

## Envisioned workflow
### Initialization
Once a new environment is created, it must be initialized. Keep in mind that each environment is it's own TERRAFORM_ROOT. Workspaces in each root are **local** and will not be shared between copies of the repository. Currently in Terraform CE all the workspace command does is create a file called `.terraform/environment` with the workspace name in it and set the `${terraform.workspace}` variable.

1. Initialize the backend:
```
terraform --init --backend-config=00-backend-config.auto.tfvars.json
```

2. Refresh the environment state:
```
terraform refresh
```
3. Add the new environment and service(s) after the list of other data sources to the 00-main.tf. See the existing ones for examples (WIP).

### Use the env/workspace model

Once your new environment directory is initialized create or select the desired workspace.

The current model is to contain a service inside it's own file and pass a shared module the appropriate variables based on environment. See [`email.tf`](envs/uat/email.tf) for an example.

For the *email* service in the *uat* environment we would name the workspace `email-uat`. Make sure you are in the correct workspace for the service you're working on.

--
This structure is a work in progress and I'm experimenting with better ways to organize things with an eye toward how these features got to CE from Terraform Enterprise.

Please feel free to comment by opening an issue or submitting a PR for other solutions.
