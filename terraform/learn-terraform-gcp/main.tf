terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

provider "google" {
  /*project = "xiekang-playground"
  region  = "eu-west1"
  zone    = "europe-west1-c"*/
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
// resource: resource type, resource name
resource "google_compute_network" "network" {
  name = var.network_name
  auto_create_subnetworks = false
  mtu = 1460
}

resource "google_compute_subnetwork" "subnetwork" {
  name    = var.subnetwork_name
  network = google_compute_network.network.id
  private_ip_google_access = true
  ip_cidr_range = "192.168.0.0/16"
}

data "google_secret_manager_secret_version" "retrieved_secret" {
  project = var.project_id
  secret = "my-test"
  version = "latest"
}

resource "google_compute_firewall" "allow_ssh_via_iap" {
  project = var.project_id
  name = "${var.instance_name}-allow-ssh-iap"
  network = google_compute_subnetwork.subnetwork.network
  direction = "INGRESS"
  priority = 1000
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags = ["iap-ssh-target"]
}

resource "google_compute_instance" "vm_instance" {
  machine_type = "e2-medium"
  name         = "terraform-instance-1"
  tags = ["test", "scheduled"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }
  # Metadata to pass initial configuration (cloud-init)
  metadata = {
    enable-oslogin = "TRUE"
    ssh-keys = "${var.ssh_username}:${file("./.ssh/gcp-key.pub")}"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.id
  }
  service_account {
    email = "130065393661-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute"
    ]
  }
  allow_stopping_for_update = true

}

resource "null_resource" "upload_script" {
  depends_on = [google_compute_instance.vm_instance]

  # you can use provisioners to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.
  provisioner "file" {
    content = templatefile("my_script.sh.tpl", {secret_key_value=data.google_secret_manager_secret_version.retrieved_secret.secret_data})
    destination = "/home/${var.ssh_username}/my_script.sh"
    connection {
      type    = "ssh"
      user    = var.ssh_username
      private_key = file("./.ssh/gcp-key")
      host    = google_compute_instance.vm_instance.network_interface.0.network_ip
      timeout = "1m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_username}/my_script.sh",
      "(crontab -l 2>/dev/null; echo \"0,30 * * * * /home/${var.ssh_username}/my_script.sh\") | crontab -"
    ]
    connection {
      type    = "ssh"
      user    = var.ssh_username
      private_key = file("./.ssh/gcp-key")
      host    = google_compute_instance.vm_instance.network_interface.0.network_ip
      timeout = "1m"
    }
  }
}