# Load Balancer IP
output "load_balancer_ip" {
  description = "Public IP of the load balancer"
  value       = google_compute_instance.load_balancer.network_interface[0].access_config[0].nat_ip
}

# Web Server IPs
output "web_server_ips" {
  description = "Internal IPs of web servers"
  value       = google_compute_instance.web_servers[*].network_interface[0].network_ip
}

# App Server IPs
output "app_server_ips" {
  description = "Internal IPs of app servers"
  value       = google_compute_instance.app_servers[*].network_interface[0].network_ip
}

# Database Server IPs
output "db_master_ip" {
  description = "Internal IP of database master"
  value       = google_compute_instance.db_master.network_interface[0].network_ip
}

output "db_replica_ip" {
  description = "Internal IP of database replica"
  value       = google_compute_instance.db_replica.network_interface[0].network_ip
}

# Ansible Inventory (auto-generated)
output "ansible_inventory" {
  description = "Ansible inventory in INI format"
  value       = <<-EOT
[load_balancer]
lb-server ansible_host=${google_compute_instance.load_balancer.network_interface[0].access_config[0].nat_ip}

[web_servers]
web-server-1 ansible_host=${google_compute_instance.web_servers[0].network_interface[0].network_ip}
web-server-2 ansible_host=${google_compute_instance.web_servers[1].network_interface[0].network_ip}

[app_servers]
app-server-1 ansible_host=${google_compute_instance.app_servers[0].network_interface[0].network_ip}
app-server-2 ansible_host=${google_compute_instance.app_servers[1].network_interface[0].network_ip}

[db_servers]
db-master ansible_host=${google_compute_instance.db_master.network_interface[0].network_ip} db_role=master
db-replica ansible_host=${google_compute_instance.db_replica.network_interface[0].network_ip} db_role=replica

[all:vars]
ansible_user=${var.ssh_user}
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -W %h:%p -q ${var.ssh_user}@${google_compute_instance.load_balancer.network_interface[0].access_config[0].nat_ip}"'
EOT
}

# SSH Connection Commands
output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    load_balancer = "ssh ${var.ssh_user}@${google_compute_instance.load_balancer.network_interface[0].access_config[0].nat_ip}"
  }
}
