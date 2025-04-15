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

## Fundamentals

### CLI

```bash 
# initialize the directory
terraform init [-upgrade]
# format the configuration
terraform fmt
# validate the configuration
terraform validate
# execution plan 
terraform plan [-destroy|-out <file_name>|-replace|-target]
# create infrastructure
terraform apply [<file_name>|-replace|-target|-var <variable_name>=<value>|-var-file <file_path>]
# inspect state
terraform show [-json <file_name> | jq > <file_name>.json]
# destroy
terraform destroy
# output value
terraform output [-json|<file_name>]
# download the new module
terraform get
# for jq
jq '.terraform_version, .format_version' <file_name>.json
# get state list for replace
terraform state list
# open interactive console --> working with troubleshooting in variable definitions
terraform console
# set terraform log level and store the log into a separate file
set TF_LOG=INFO # Linux export TF_LOG=INFO
set TF_LOG_PATH=terraform.log # Linux export TF_LOG_PATH=terraform.log
unset TF_LOG # Linux unset after execution
```

#### main.tf

````terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.9.0"
    }
  }
  required_version = "~> 1.1.9" # adding min required_version for terraform
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

- when you applied your configuration, Terraform wrote data into a file called _terraform.tfstate_.
  Terraform stores the IDs and properties of the resources it manages in this file, so that it can
  update or destroy those resources going forward.
- the prefix `~` means that terraform will update the resource in-place.
- the prefix ``+/-`` means that terraform will destroy and recreate the resource, rather than updating it in-place.
- ``terraform destroy`` is the inverse of `terraform apply` in that it terminates all the resources specified in your
  terraform state. It does not destroy resources running elsewhere that are not managed by the current terraform project
- _.terraform.lock.hcl_ records the versions and hashes of the providers used in this run. This ensures consistent
  Terraform runs in different environments. Terraform will always use the version recorded in the lock file.
- `terraform apply -replace` is used to force the recreation of a specific resource. Terraform will first destroy the
  existing resource and then create a new one in its place.
- ``terraform apply -target`` is used to focus the apply operation on a specific resource or a set of resource.
  Terraform will only consider changes related to the targeted resources and their dependencies.
- terraform version constraints

| required version | meaning                                           |
|------------------|---------------------------------------------------|
| 1.7.5            | only Terraform v1.7.5                             | 
| >= 1.7.5         | any terraform v1.7.5 or greater                   | 
| ~> 1.7.5         | any Terraform v1.7.x, but not v1.8 or later       |
| >= 1.7.5 < 1.9.5 | Terraform v1.7.5 or greater, but less than v1.9.5 |

- Terraform providers manage resources by communicating between Terraform and target APIs.

#### variables.tf

````terraform
variable "aws_region" {
  description = "AUS region"
  type        = string
  default     = "us-west-2"
}

variable "resource_tags" {
  description = "Tags to set for all resources"
  type = map(string)
  default = {
    project     = "my-project",
    environment = "dev"
  }
  validation {
    condition     = length(var.resource_tags["project"]) <= 16 && length(regexall("[^a-zA-Z0-9-]", var.resource_tags["project"])) == 0
    error_message = "The project tag must be no more than 16 characters, and only contain letters, numbers, and hyphens."
  }
  validation {
    condition     = length(var.resource_tags["environment"]) <= 8 && length(regexall("[^a-zA-Z0-9-]", var.resource_tags["environment"])) == 0
    error_message = "The environment tag must be no more than 8 characters, and only contain letters, numbers, and hyphens."
  }
}
````

- ``variable "variable_name"`` contains 3 options - _description_, _type_, _default_
    - _type = string|number|bool|list|set|map|object|tuple|any_
    - setting a variable as _ephemeral_ makes it available during runtime, but Terraform omits ephemeral values from
      state and plan files.
    - ``slice(one_list, from, to_exclude)`` to sublist the original given list.
    - interpolate variables in strings: `"web-sg-${var.resource_tags["project"]}-${var.resource_tags["environment"]}"`

#### outputs.tf

````terraform
output "db_username" {
  description = "Database administrator username"
  value       = aws_db_instance.database.username
  sensitive   = true
}
```` 

- Terraform output values let you export structured data about your resources. You can use this data to configure
  other parts of your infrastructure with automation tolls, or as a data source for another Terraform workspace. Outputs
  are also let you expose data from a child module to a root module.
- you can add sensitive option into your _output_ definition, which redact the sensitive information to print out in
  console.

## Provisioners

- you can use provisioners to model specific actions on the local machine or on a remote machine in order to prepare
  servers or other infrastructure objects for service.
- provisioners could make your configuration less predictable and harder to manager. For more complex scenarios,
  consider
  using tools like Packer to pre-bake your image or using configuration management tools (Ansible, Chef, Puppet) invoked
  by a provisioner or cloud-init

## use cases

### create google compute engine resources and upload my own script.sh and trigger it daily