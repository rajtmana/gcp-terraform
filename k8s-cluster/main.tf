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

resource "google_container_cluster" "mservice" {
  provider   = "google-beta"
  name       = "mservice-dev-cluster"
  region     = "${var.gcp_region}"
  network    = "${var.gcp_network}"
  subnetwork = "${var.gcp_subnetwork}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  initial_node_count = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name = "mservice-pod-secondary-range"
    services_secondary_range_name = "mservice-service-secondary-range"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      foo = "mservice"
    }

    tags = ["owner", "rajt"]
  }

  addons_config {
    http_load_balancing {
      disabled = true
    }

    horizontal_pod_autoscaling {
      disabled = true
    }

    istio_config {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "mservice_preemptible_nodes" {
  name       = "mservice-node-pool"
  region     = "${var.gcp_region}"
  cluster    = "${google_container_cluster.mservice.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster
# by using certificate-based authentication.
output "client_certificate" {
  value = "${google_container_cluster.mservice.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.mservice.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.mservice.master_auth.0.cluster_ca_certificate}"
}
