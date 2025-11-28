# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "three-tier-vpc"
  auto_create_subnetworks = false
}

# Public Subnet (Load Balancer)
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Web Tier Subnet
resource "google_compute_subnetwork" "web_subnet" {
  name          = "web-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# App Tier Subnet
resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Database Tier Subnet
resource "google_compute_subnetwork" "db_subnet" {
  name          = "db-subnet"
  ip_cidr_range = "10.0.4.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}
