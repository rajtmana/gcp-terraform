# Infrastructure as Code for Google Cloud Platform Using Terraform
How to create GCP infrastructure using [Hashicorp Terraform](https://www.terraform.io/). This repository contains simple set of Terraform scripts to create individual GCP services. It is also important to note that, this is not following any **best practices** of writing Terraform code. The idea here is to make things work for the first time and improvise based on your needs. For all of the examples to work, the following pre-requisites are required.
* A valid GCP account
* The key of the user/service account got downloaded into your local machine
* Terraform is installed and configured (Terraform v0.11.11 is being used here)
* All the examples are run from a Mac machine

When a security key is downloaded, keep it in a local directory and export the location in an environment variable. Make sure that the key is removed as and when your needs are over to prevent from your account being compromised. Key rotation is also a good method.
```bash
export GOOGLE_CLOUD_KEYFILE_JSON=‎⁨‎⁨‎⁨‎⁨/Users/RajT/workspace/gcp-terraform/keys/infra.json
echo $GOOGLE_CLOUD_KEYFILE_JSON
```
When you go to each of the directories, make sure that you edit the scripts to include the following parameters.
* Your GCP project ID
* Your preferred GCP region
* Your preferred GCP zone

Once you are done with all these steps given above, use the following Terraform commands
```bash
# Make the initialization
terraform init
# See the plan of action
terraform plan
# Create the infrastructure
terraform apply
# Once all the work is completed, destroy the infrastructure that you have created
terraform destroy
```

## List of Scripts Directories
The following directories contain Terraform scripts. Some of the scripts are dependent on the scripts in the other directories. Wherever there are dependencies like this, it is called out with **DEPENDENCIES**
* **cs** - This contains Terraform scripts to create a Google Cloud Storage bucket in a given region
* **vpc** - This contains Terraform scripts to create a VPC with subnet for creating your GCP service resources
* **k8s-cluster** - This contains Terraform scripts to create a Kubernetes (K8S) cluster with Istio enabled. **DEPENDENCIES** - The VPC created using the scripts in the directory **vpc** is used to create the K8S cluster.

## References
* Managing GCP Projects with Terraform - https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
* Understanding GCP Roles - https://cloud.google.com/iam/docs/understanding-roles
* Using Terraform with Makefiles - http://saurabh-hirani.github.io/writing/2017/08/02/terraform-makefile
