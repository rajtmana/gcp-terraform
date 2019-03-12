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
    range_name    = "mservice-pod-secondary-range"
    ip_cidr_range = "10.96.0.0/11"
  }
  secondary_ip_range {
    range_name    = "mservice-service-secondary-range"
    ip_cidr_range = "10.94.0.0/18"
  }

}
