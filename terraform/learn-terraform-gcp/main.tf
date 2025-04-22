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

// vm without public access

resource "google_storage_bucket" "script_bucket" {
  location = "EU"
  name     = "playground-startup-script-bucket"
}

resource "google_storage_bucket_object" "startup_script_object" {
  depends_on = [google_storage_bucket.script_bucket]
  bucket = "playground-startup-script-bucket"
  name   = "my-script.sh"
  source = "./my_script.sh"
}

resource "google_storage_bucket_object" "startup_script_main_object" {
  depends_on = [google_storage_bucket.script_bucket]
  bucket = "playground-startup-script-bucket"
  name   = "main.sh"
  source = "./main.sh"
}

# 1. create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "internal-network"
  auto_create_subnetworks = false
}

# 2. create a subnetwork
resource "google_compute_subnetwork" "subnet" {
  name          = "internal-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc_network.id
  region        = var.region
  private_ip_google_access = true
}

# 3. firewall rule to allow IAP access
resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["35.235.240.0/20", "35.235.252.0/22", "35.235.1.0/24", "35.235.128.0/20"]
  target_tags = ["iap-allowed"]
}

/**
# 4. reserve an internal IP address --> Optional
resource "google_compute_address" "internal" {
  name       = "internal-ip"
  subnetwork = google_compute_subnetwork.subnet.id
  region     = var.region
}**/

# 5. create the VM with only an internal IP and startup script
resource "google_compute_instance" "vm_internal_ip" {
  depends_on = [google_storage_bucket_object.startup_script_main_object]
  machine_type = "e2-medium"
  name         = "terraform-instance-internal-access"
  zone         = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  metadata = {
    ssh-keys       = "${var.ssh_username}:${file("./.ssh/gcp-key.pub")}"
    startup-script-url ="gs://playground-startup-script-bucket/main.sh"
  }

  network_interface {
    //network = "default"
    subnetwork = google_compute_subnetwork.subnet.id
    //subnetwork = "default"
  }

  service_account {
    email = "130065393661-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_write",
    ]
  }
  tags = ["iap-allowed"]
}

/**
resource "null_resource" "upload_script" {
  depends_on = [google_compute_instance.vm_internal_ip]

  provisioner "remote-exec" {
    inline = [
      "gsutil -m cp -r gs://playground-startup-script-bucket/my-script.sh /home/xiekang.zhang/my-script.sh",
      "chmod +x /home/${var.ssh_username}/my_script.sh",
      "/home/${var.ssh_username}/my_script.sh",
      "(crontab -l 2>/dev/null; echo \"0,30 * * * * /home/${var.ssh_username}/my_script.sh\") | crontab -"
    ]
    connection {
      type    = "ssh"
      user    = var.ssh_username
      private_key = file("./.ssh/gcp-key")
      host    = google_compute_instance.vm_internal_ip.network_interface.0.network_ip
      timeout = "1m"
    }
  }
}**/