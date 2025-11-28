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
  default = "app-server-{{timestamp}}"
}

source "googlecompute" "app_server" {
  project_id          = var.project_id
  source_image_family = var.source_image_family
  zone                = var.zone
  image_name          = var.image_name
  image_description   = "App server image with Node.js for 3-tier infrastructure"
  ssh_username        = "packer"
  machine_type        = "e2-medium"
  disk_size           = 20
  
  tags = ["packer", "app-server"]
}

build {
  sources = ["source.googlecompute.app_server"]

  # Update system
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
    ]
  }

  # Install Node.js and npm
  provisioner "shell" {
    inline = [
      "curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "sudo apt-get install -y build-essential",
      "node --version",
      "npm --version",
    ]
  }

  # Install PM2 for process management
  provisioner "shell" {
    inline = [
      "sudo npm install -g pm2",
      "pm2 --version",
    ]
  }

  # Install additional tools
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y curl wget git postgresql-client",
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

  # Run Ansible provisioner for app server base setup
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-app.yml"
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
