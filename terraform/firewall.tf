# Allow SSH from admin IP to all instances
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-from-admin"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.admin_ip_ranges
  target_tags   = ["load-balancer", "web-server", "app-server", "db-server"]
}

# Allow SSH from Load Balancer (Bastion) to all instances
resource "google_compute_firewall" "allow_ssh_from_bastion" {
  name    = "allow-ssh-from-bastion"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["load-balancer"]
  target_tags = ["web-server", "app-server", "db-server"]
}

# Allow HTTP/HTTPS from internet to load balancer only
resource "google_compute_firewall" "allow_http_lb" {
  name    = "allow-http-https-to-lb"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["load-balancer"]
}

# Allow HTTP/HTTPS from LB to web servers
resource "google_compute_firewall" "allow_lb_to_web" {
  name    = "allow-lb-to-web"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_tags = ["load-balancer"]
  target_tags = ["web-server"]
}

# Allow port 3000 from web servers to app servers
resource "google_compute_firewall" "allow_web_to_app" {
  name    = "allow-web-to-app"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_tags = ["web-server"]
  target_tags = ["app-server"]
}

# Allow PostgreSQL from app servers to database servers
resource "google_compute_firewall" "allow_app_to_db" {
  name    = "allow-app-to-db"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app-server"]
  target_tags = ["db-server"]
}

# Allow PostgreSQL replication between database servers
resource "google_compute_firewall" "allow_db_replication" {
  name    = "allow-db-replication"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["db-server"]
  target_tags = ["db-server"]
}

# Deny all other inbound traffic (implicit, but explicit for clarity)
resource "google_compute_firewall" "deny_all" {
  name     = "deny-all-inbound"
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}
