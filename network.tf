# ---------------------------------------------------------------------------
# VPC, Subnet, VPC Connector, Private Services Access (for Cloud SQL)
# ---------------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                    = "${var.resource_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "main" {
  name                     = "${var.resource_prefix}-subnet"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = var.region
  network                  = google_compute_network.main.id
  project                  = var.project_id
  private_ip_google_access = true
}

# Serverless VPC Access connector (Cloud Run → VPC)
resource "google_vpc_access_connector" "connector" {
  name          = "${var.resource_prefix}-conn"
  region        = var.region
  project       = var.project_id
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.main.name

  depends_on = [google_project_service.apis]
}

# Allocate an IP range for Private Services Access (Cloud SQL private IP)
resource "google_compute_global_address" "private_services" {
  name          = "${var.resource_prefix}-private-svc-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  address       = "10.64.0.0"
  network       = google_compute_network.main.id
  project       = var.project_id
}

# Peer the VPC with Google-managed services network (for Cloud SQL)
resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]

  depends_on = [google_project_service.apis]
}
