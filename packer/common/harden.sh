#!/bin/bash
# Common hardening and security script for all Packer images

set -e

echo "=== Starting security hardening ==="

# Disable root login
echo "Disabling root login..."
sudo passwd -l root

# Configure firewall (basic rules, will be configured by Ansible)
echo "Setting up basic firewall..."
sudo apt-get install -y ufw
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh

# Install security updates automatically
echo "Configuring unattended upgrades..."
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Harden SSH
echo "Hardening SSH configuration..."
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Install fail2ban
echo "Installing fail2ban..."
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban

# Set timezone to UTC
echo "Setting timezone to UTC..."
sudo timedatectl set-timezone UTC

# Install monitoring tools
echo "Installing monitoring tools..."
sudo apt-get install -y htop iotop nethogs

echo "=== Security hardening complete ==="
