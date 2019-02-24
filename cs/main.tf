# Ref - https://www.terraform.io/docs/providers/google/r/storage_bucket.html
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
resource "google_storage_bucket" "composer_dag" {
  name      = "${var.gcp_project}-composer-dag"
  project   = "${var.gcp_project}"
  location  = "${var.gcp_region}"
}
