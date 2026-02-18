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
  name                    = "fastclaws-enterprise-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name                     = "fastclaws-private-subnet"
  ip_cidr_range            = "10.46.20.0/24" # /24 = 254 usable IPs
  network                  = google_compute_network.vpc.id
  region                   = var.region
  private_ip_google_access = true
}

# --- Cloud Router + Cloud NAT ---

resource "google_compute_router" "router" {
  name    = "fastclaws-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "fastclaws-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# --- Firewall Rules ---

resource "google_compute_firewall" "allow_iap" {
  name    = "fastclaws-allow-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Google's IAP tunnel IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-access"]
}

resource "google_compute_firewall" "deny_ingress" {
  name     = "fastclaws-deny-ingress"
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
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

# --- Service Account ---

resource "google_service_account" "instance" {
  account_id   = "${var.instance_name}-sa"
  display_name = "Service account for ${var.instance_name}"
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
    subnetwork = google_compute_subnetwork.private.id
    # No access_config — no public IP
  }

  service_account {
    email  = google_service_account.instance.email
    scopes = ["cloud-platform"]
  }

  tags = ["iap-access"]

  labels = {
    project = "fastclaws"
  }
}
