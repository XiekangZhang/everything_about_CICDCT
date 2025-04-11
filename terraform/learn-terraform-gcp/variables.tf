variable "project" {}

//variable "credentials_file" {}

variable "region" {
  default = "eu-west1"
}

variable "zone" {
  default = "europe-west1-c"
}

variable "username" {
  default     = "xiekang"
  description = "your username"
  type        = string
}