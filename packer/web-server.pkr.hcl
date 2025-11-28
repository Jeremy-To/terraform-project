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
  default = "web-server-{{timestamp}}"
}

source "googlecompute" "web_server" {
  project_id          = var.project_id
  source_image_family = var.source_image_family
  zone                = var.zone
  image_name          = var.image_name
  image_description   = "Web server image with Nginx for 3-tier infrastructure"
  ssh_username        = "packer"
  machine_type        = "e2-medium"
  disk_size           = 20
  
  tags = ["packer", "web-server"]
}

build {
  sources = ["source.googlecompute.web_server"]

  # Update system
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nginx curl wget git",
    ]
  }

  # Basic Nginx configuration
  provisioner "shell" {
    inline = [
      "sudo systemctl enable nginx",
      "sudo systemctl stop nginx",  # Will be configured by Ansible
    ]
  }

  # Copy Ansible provisioning script
  provisioner "file" {
    source      = "../ansible/roles"
    destination = "/tmp/ansible-roles"
  }

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",
    ]
  }

  # Run Ansible provisioner for web server base setup
  provisioner "ansible-local" {
    playbook_file = "../ansible/playbooks/packer-web.yml"
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
