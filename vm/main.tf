variable "gcp_project" {
  type    = "string"
  default = "protean-1217618"
}

variable "gcp_region" {
  type    = "string"
  default = "europe-west2"
}

variable "gcp_zone" {
  type    = "string"
  default = "europe-west2-a"
}

variable "gcp_network" {
  type    = "string"
  default = "mservice-network"
}

variable "gcp_subnetwork" {
  type    = "string"
  default = "mservice-subnetwork"
}

provider "google" {
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

provider "google-beta" {
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

resource "google_compute_network" "mservice_network" {
  name                    = "mservice-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mservice_subnetwork" {
  name          = "mservice-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "${var.gcp_region}"
  network       = "${google_compute_network.mservice_network.self_link}"

  secondary_ip_range {
    range_name    = "mservice-cluster-ip-range"
    ip_cidr_range = "10.96.0.0/11"
  }

  secondary_ip_range {
    range_name    = "mservice-service-ip-range"
    ip_cidr_range = "10.94.0.0/18"
  }
}

resource "google_compute_firewall" "mservice_allow_ssh" {
  name      = "mservice-allow-ssh"
  network   = "${google_compute_network.mservice_network.name}"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-mservice"]
}

resource "google_compute_instance" "mservice_bastion" {
  name         = "mservice-bastion"
  machine_type = "n1-standard-1"
  zone         = "${var.gcp_zone}"

  tags                      = ["ssh-mservice"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.mservice_subnetwork.self_link}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    service = "mservicebastion"
  }

  service_account {
    scopes = [
      "userinfo-email",
      "compute-rw",
      "storage-rw",
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/cloud-platform.read-only",
      "https://www.googleapis.com/auth/cloudplatformprojects",
      "https://www.googleapis.com/auth/cloudplatformprojects.readonly",
    ]
  }
}
