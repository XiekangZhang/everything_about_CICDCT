variable "project_id" {
  default="xiekang-playground"
}

//variable "credentials_file" {}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-c"
}

variable "ssh_username" {
  default = "xiekang.zhang"
  type    = string
}

variable "instance_name" {
  default = "instance-no-public-ip"
}

variable "network_name" {
  default = "vm-network"
}

variable "subnetwork_name" {
  default = "vm-subnetwork"
}