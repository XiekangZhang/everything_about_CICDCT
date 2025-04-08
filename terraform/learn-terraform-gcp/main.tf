terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28.0"
    }
  }
}

provider "google" {
  /*project = "xiekang-playground"
  region  = "eu-west1"
  zone    = "europe-west1-c"*/
  project = var.project
  region  = var.region
  zone    = var.zone
}
// resource: resource type, resource name
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
  machine_type = "f1-micro"
  name         = "terraform-instance"
  tags = ["web", "dev"]
  boot_disk {
    initialize_params {
      // image = "debian-cloud/debian-11"
      image = "cos-cloud/cos-stable"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
}