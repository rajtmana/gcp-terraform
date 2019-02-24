# Ref - https://www.terraform.io/docs/providers/google/r/composer_environment.html
variable "gcp_project" {
  type    = "string"
  default = "protean-1217618"
}

variable "gcp_region" {
  type    = "string"
  default = "europe-west1"
}

variable "gcp_zone" {
  type    = "string"
  default = "europe-west1-a"
}

provider "google" {
  project = "${var.gcp_project}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

resource "google_composer_environment" "mservice_composer" {
  name   = "mservice-composer"
  region = "${var.gcp_region}"

  config {
    node_count = 3

    node_config {
      zone         = "${var.gcp_zone}"
      machine_type = "n1-standard-1"
      network      = "${google_compute_network.composer_qa_network.self_link}"
      subnetwork   = "${google_compute_subnetwork.composer_qa_subnetwork.self_link}"
    }
  }
}

resource "google_compute_network" "composer_qa_network" {
  name                    = "composer-qa-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "composer_qa_subnetwork" {
  name          = "composer-qa-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "${var.gcp_region}"
  network       = "${google_compute_network.composer_qa_network.self_link}"
}
