packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP Zone"
}

variable "source_image_family" {
  type    = string
  default = "ubuntu-2204-lts"
}

variable "image_name" {
  type    = string
  default = "db-server-{{timestamp}}"
}

source "googlecompute" "db_server" {
  project_id          = var.project_id
  source_image_family = var.source_image_family
  zone                = var.zone
  image_name          = var.image_name
  image_description   = "Database server image with PostgreSQL 15 for 3-tier infrastructure"
  ssh_username        = "packer"
  machine_type        = "e2-medium"
  disk_size           = 20
  
  tags = ["packer", "db-server"]
}

build {
  sources = ["source.googlecompute.db_server"]

  # Update system
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
    ]
  }

  # Install PostgreSQL 15
  provisioner "shell" {
    inline = [
      "sudo sh -c 'echo \"deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main\" > /etc/apt/sources.list.d/pgdg.list'",
      "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -",
      "sudo apt-get update",
      "sudo apt-get install -y postgresql-15 postgresql-contrib-15",
    ]
  }

  # Stop PostgreSQL (will be configured by Ansible)
  provisioner "shell" {
    inline = [
      "sudo systemctl stop postgresql",
      "sudo systemctl enable postgresql",
    ]
  }

  # Install backup tools
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y curl wget git",
    ]
  }

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
    ]
  }

  # Run Ansible provisioner for database server base setup
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-db.yml"
    role_paths    = [
      "../ansible/roles/common"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*",
      "sudo journalctl --rotate",
      "sudo journalctl --vacuum-time=1s",
      "history -c"
    ]
  }
}
