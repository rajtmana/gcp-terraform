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
  ip_cidr_range = "10.1.0.0/16"
  region        = "${var.gcp_region}"
  network       = "${google_compute_network.mservice_network.self_link}"

  secondary_ip_range {
    range_name    = "mservice-cluster-ip-range"
    ip_cidr_range = "10.2.0.0/20"
  }

  secondary_ip_range {
    range_name    = "mservice-service-ip-range"
    ip_cidr_range = "192.168.0.0/24"
  }
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

  # The desired configuration options for master authorized networks.
  # Access to the master must be from internal IP addresses. So don't give any CIDR blocks inside
  # Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists).
  # Use this as the whitelisting option
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "${google_compute_subnetwork.mservice_subnetwork.ip_cidr_range}"
      display_name = "${google_compute_subnetwork.mservice_subnetwork.name} - IP Range"
    }
  }

  # The CIDR block in this section should not overlap with any of the VPC's primary or secondary address range
  # https://stackoverflow.com/questions/51995973/understanding-master-ipv4-cidr-when-provisioning-private-gke-clusters
  # https://github.com/GoogleCloudPlatform/gke-networking-demos/tree/master/gke-to-gke-peering
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${google_compute_subnetwork.mservice_subnetwork.secondary_ip_range.0.range_name}"
    services_secondary_range_name = "${google_compute_subnetwork.mservice_subnetwork.secondary_ip_range.1.range_name}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      service = "mservice"
    }

    tags = ["http-server", "https-server"]
  }

  addons_config {
    # Masters run on VMs in Google-owned projects. In a private cluster, you can control access to the master.
    # A private cluster can use an HTTP(S) load balancer or a network load balancer to accept incoming traffic, even though the cluster nodes do not have public IP addresses.
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    istio_config {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = false
    }
  }
}

resource "google_container_node_pool" "mservice_nodes" {
  name       = "mservice-node-pool"
  region     = "${var.gcp_region}"
  cluster    = "${google_container_cluster.mservice.name}"
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
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
