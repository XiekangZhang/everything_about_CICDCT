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
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

// vm with public access works!
resource "google_compute_instance" "vm_instance" {
  machine_type = "e2-medium"
  name         = "terraform-instance-public-access"
  tags = ["test", "scheduled"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }
  metadata = {
    ssh-keys = "${var.ssh_username}:${file("./.ssh/gcp-key.pub")}"
  }

  network_interface {
    network = "default"
    access_config {}
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

  provisioner "file" {
    source      = "my_script.sh"
    destination = "/home/${var.ssh_username}/my_script.sh"
    connection {
      type    = "ssh"
      user    = var.ssh_username
      private_key = file("./.ssh/gcp-key")
      host    = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
      timeout = "1m"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ssh_username}/my_script.sh",
      "/home/${var.ssh_username}/my_script.sh",
      "(crontab -l 2>/dev/null; echo \"0,30 * * * * /home/${var.ssh_username}/my_script.sh\") | crontab -"
    ]
    connection {
      type    = "ssh"
      user    = var.ssh_username
      private_key = file("./.ssh/gcp-key")
      host    = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
      timeout = "1m"
    }
  }
}

// vm without public access