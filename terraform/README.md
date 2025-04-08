# terraform

- terraform is an infrastructure as code tool that lets you build, change, and version infrastructure safely and
  efficiently. This includes low-level components like compute instances, storage, and networking; and high-level
  components like DNS entries and SaaS features.
- The core Terraform workflow consists of 3 stages:
    - **write**: you define resources, which may be across multiple cloud providers and services.
    - **plan**: terraform creates an execution plan describing the infrastructure it will create, update or destroy
      based on the existing infrastructure and your configuration
    - **apply**: on approval, Terraform performs the proposed operations in the correct order, respecting any
      resource dependencies.
- To deploy infrastructure with Terraform:
    - **scope**: identify the infrastructure for your project
    - **author**: write the configuration for your infrastructure
    - **initialize**: install the plugins Terraform needs to manage the infrastructure
    - **plan**: preview the changes Terraform will make to match your configuration
    - **apply**: make the planned changes

## GCP Quickstart

````terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.9.0"
    }
  }
}

provider "google" {
  project = "<PROJECT_ID>"
  region  = "us_central1"
  zone    = "us_ceontral1-c"
}

// resource <resource_type> <resource_name>
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
````

- useful terraform commands

```bash 
# initialize the directory
terraform init
# format the configuration
terraform fmt
# validate the configuration
terraform validate
# execution plan 
terraform plan
# create infrastructure
terraform apply 
# inspect state
terraform show
# destroy
terraform destroy
# output value
terraform output
```

- when you applied your configuration, Terraform wrote data into a file called _terraform.tfstate_.
  Terraform stores the IDs and properties of the resources it manages in this file, so that it can
  update or destroy those resources going forward.
- the prefix `~` means that terraform will update the resource in-place.
- the prefix ``+/-`` means that terraform will destroy and recreate the resource, rather than updating it in-place.
- ``terraform destroy`` is the inverse of `terraform apply` in that it terminates all the resources specified in your
  terraform state. It does not destroy resources running elsewhere that are not managed by the current terraform project