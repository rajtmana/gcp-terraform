# Ref - https://www.terraform.io/docs/providers/google/r/google_service_account_iam.html
variable "gcp_project" {
  type    = "string"
  default = "protean-1217618"
}

provider "google" {
  project = "${var.gcp_project}"
}
resource "google_service_account" "mservice_infra_service_account" {
  account_id   = "mservice-infra-service-account"
  display_name = "Infrastructure Service Account"
}

resource "google_project_iam_custom_role" "mservice_infra_admin" {
  role_id     = "mservice_infra_admin"
  title       = "mservice_infra_admin"
  description = "Infrastructure Administrator Custom Role"
  permissions = ["compute.disks.create", "compute.firewalls.create", "compute.firewalls.delete", "compute.firewalls.get", "compute.instanceGroupManagers.get", "compute.instances.create", "compute.instances.delete", "compute.instances.get", "compute.instances.setMetadata", "compute.instances.setServiceAccount", "compute.instances.setTags", "compute.machineTypes.get", "compute.networks.create", "compute.networks.delete", "compute.networks.get", "compute.networks.updatePolicy", "compute.subnetworks.create", "compute.subnetworks.delete", "compute.subnetworks.get", "compute.subnetworks.setPrivateIpGoogleAccess", "compute.subnetworks.update", "compute.subnetworks.use", "compute.subnetworks.useExternalIp", "compute.zones.get", "container.clusters.create", "container.clusters.delete", "container.clusters.get", "container.clusters.update", "container.operations.get"]
}
resource "google_project_iam_binding" "mservice_infra_binding" {
  role = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.mservice_infra_admin.role_id}"

  members = [
    "serviceAccount:${google_service_account.mservice_infra_service_account.email}",
  ]
}
