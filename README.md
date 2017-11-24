# killTERM.xyz example DevOps sandbox.
An example of how to use various automation tools to stand up, tear down, and test a complete AWS/kubernetes environment suitable for adaptation to your own environment.

*This is a work in progress as I work through learning this stuff myself so consider this very incomplete*

I've tried to make this as modular as possible so **SIGNIFICANT MODIFICATION NEEDS TO BE DONE BEFORE THIS WILL WORK IN YOUR ENVIRONMENT - PLEASE READ CAREFULLY**

## Cost
The resources used by these examples ***WILL cost you real money*** even if you're in the free tier.  I've made attempts to keep costs as low as possible but you will incur charges for runninig these these demos.  

Remember to destroy resources when you're done for a bit so you're not spending money when you're not working on it. I'll note prices off-hand when I remember them but you should always check the current AWS pricing pages and use the [Simple Monthly Calculator](https://calculator.s3.amazonaws.com/index.html) to get an idea for how much this could cost over the course of a month if you don't destroy AWS resources.

### killTERM.zyx
[killterm.xyz](https://www.killterm.xyz/) (*Website coming soon*) is a real domain I own namely for the use of these examples.  You can either purchase a real domain in any TLD or use a private domain in a VPC. Private domains are left as an exercise for the reader to implement.

## Terraform
While not necessary  to use [terraform](https://terraform.io) I've included resources to create and destroy (almost) all of the infrastructure in AWS required to run the K8's cluster and other fun bits like SES email reception and forwarding. Please see the [README in the terraform folder](terraform/README.md) for more information.

## Docker, Packer and Ansible
This example uses [Packer](https://packer.io/) and [Ansible](https://www.ansible.com/) to provision and create [Docker](https://www.docker.com) images for both local use with minikube and a k8's cluster running on AWS.
