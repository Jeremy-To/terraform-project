variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "admin_ip_ranges" {
  description = "IP ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change to your IP in production
}

variable "web_server_image" {
  description = "Custom web server image built by Packer"
  type        = string
  default     = "projects/YOUR_PROJECT/global/images/family/web-server"
}

variable "app_server_image" {
  description = "Custom app server image built by Packer"
  type        = string
  default     = "projects/YOUR_PROJECT/global/images/family/app-server"
}

variable "db_server_image" {
  description = "Custom database server image built by Packer"
  type        = string
  default     = "projects/YOUR_PROJECT/global/images/family/db-server"
}
