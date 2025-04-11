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
  machine_type = "e2-medium"
  name         = "terraform-instance"
  tags = ["test", "scheduled"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }

  /**
   metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      chmod +x /tmp/my_script.sh
      (crontab -l 2>/dev/null; echo "0 0 * * * /tmp/my_script.sh") | crontab -
      EOF
  }
  **/

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
  # you can use provisioners to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.
  provisioner "file" {
    source      = "my_script.sh"
    destination = "/tmp/my_script.sh"

    connection {
      type = "ssh"
      user = "root"
      host = self.network_interface.0.network_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/my_script.sh",
      "(crontab -l 2>/dev/null; echo \"0 0 * * * /tmp/my_script.sh\") | crontab"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = self.network_interface.0.network_ip
    }
  }
}