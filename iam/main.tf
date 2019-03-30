variable "gcp_project" {
  type    = "string"
  default = "protean-1217618"
}

provider "google" {
  project = "${var.gcp_project}"
}

resource "google_service_account" "mservice_infra_sa" {
  account_id   = "mservice-infra-service-account"
  display_name = "Infrastructure Service Account"
}

resource "google_service_account" "mservice_svc_sa" {
  account_id   = "mservice-svc-service-account"
  display_name = "Service Deployment Service Account"
}

resource "google_project_iam_custom_role" "mservice_infra_admin_role" {
  role_id     = "mservice_infra_admin_role"
  title       = "mservice_infra_admin_role"
  description = "Infrastructure Administrator Custom Role"

  permissions = [
    "compute.disks.create",
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.instanceGroupManagers.get",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.instances.setTags",
    "compute.machineTypes.get",
    "compute.networks.create",
    "compute.networks.delete",
    "compute.networks.get",
    "compute.networks.updatePolicy",
    "compute.subnetworks.create",
    "compute.subnetworks.delete",
    "compute.subnetworks.get",
    "compute.subnetworks.setPrivateIpGoogleAccess",
    "compute.subnetworks.update",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.zones.get",
    "container.clusters.create",
    "container.clusters.delete",
    "container.clusters.get",
    "container.clusters.update",
    "container.operations.get",
  ]
}

resource "google_project_iam_custom_role" "mservice_svc_admin_role" {
  role_id     = "mservice_svc_admin_role"
  title       = "mservice_svc_admin_role"
  description = "Service Deployment Custom Role"

  permissions = [
    "container.apiServices.get",
    "container.apiServices.list",
    "container.clusters.get",
    "container.clusters.getCredentials",
  ]
}

resource "google_project_iam_binding" "mservice_infra_binding" {
  role = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.mservice_infra_admin_role.role_id}"

  members = [
    "serviceAccount:${google_service_account.mservice_infra_sa.email}",
  ]
}

resource "google_project_iam_binding" "mservice_svc_binding" {
  role = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.mservice_svc_admin_role.role_id}"

  members = [
    "serviceAccount:${google_service_account.mservice_svc_sa.email}",
  ]
}

resource "google_project_iam_binding" "mservice_infra_sa_adm_binding" {
  role = "roles/iam.serviceAccountAdmin"

  members = [
    "serviceAccount:${google_service_account.mservice_infra_sa.email}",
  ]
}

resource "google_project_iam_binding" "mservice_infra_sa_usr_binding" {
  role = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${google_service_account.mservice_infra_sa.email}",
  ]
}
