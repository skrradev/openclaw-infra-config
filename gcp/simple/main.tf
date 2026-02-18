terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# --- VPC Network ---

resource "google_compute_network" "vpc" {
  name                    = "fastclaws-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "fastclaws-subnet"
  ip_cidr_range = "10.44.10.0/24" # /24 = 254 usable IPs
  network       = google_compute_network.vpc.id
  region        = var.region
}

# --- Firewall Rules ---

resource "google_compute_firewall" "allow_ssh" {
  name    = "fastclaws-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_cidr]
  target_tags   = ["ssh-access"]
}

resource "google_compute_firewall" "allow_egress" {
  name      = "fastclaws-allow-egress"
  network   = google_compute_network.vpc.name
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# --- Compute Instance ---

resource "google_compute_instance" "server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts"
      size  = var.disk_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  tags = ["ssh-access"]

  labels = {
    project = "fastclaws"
  }
}
