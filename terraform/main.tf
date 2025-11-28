terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Load Balancer Instance
resource "google_compute_instance" "load_balancer" {
  name         = "lb-server"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["load-balancer", "http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = var.web_server_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    
    access_config {
      # Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Web Server Instances
resource "google_compute_instance" "web_servers" {
  count        = 2
  name         = "web-server-${count.index + 1}"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = var.web_server_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.web_subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# App Server Instances
resource "google_compute_instance" "app_servers" {
  count        = 2
  name         = "app-server-${count.index + 1}"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["app-server"]

  boot_disk {
    initialize_params {
      image = var.app_server_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

# Database Instances
resource "google_compute_instance" "db_master" {
  name         = "db-master"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["db-server", "db-master"]

  boot_disk {
    initialize_params {
      image = var.db_server_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.db_subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "db_replica" {
  name         = "db-replica"
  machine_type = "e2-small"
  zone         = var.zone

  tags = ["db-server", "db-replica"]

  boot_disk {
    initialize_params {
      image = var.db_server_image
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.db_subnet.id
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}
