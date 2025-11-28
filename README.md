# 3-Tier Infrastructure on GCP

A production-grade, fully automated 3-tier infrastructure deployed on Google Cloud Platform using Terraform and PowerShell.

## 🏗️ Architecture

The infrastructure consists of **7 Virtual Machines** distributed across 4 subnets for maximum security:

| Tier | Component | Count | IP Range | Description |
|------|-----------|-------|----------|-------------|
| **Public** | **Load Balancer** | 1 | `34.x.x.x` | Nginx Bastion & Reverse Proxy. Entry point. |
| **Web** | **Web Servers** | 2 | `10.0.2.x` | Nginx Web Servers serving static content. |
| **App** | **App Servers** | 2 | `10.0.3.x` | Node.js API Servers (PM2 managed). |
| **DB** | **Databases** | 2 | `10.0.4.x` | PostgreSQL Master/Replica cluster. |

### Security Features
- **Cloud NAT**: Allows private instances to install updates without public IPs.
- **Firewall**: Strict rules. LB can only reach Web. Web can only reach App. App can only reach DB.
- **Bastion Host**: The Load Balancer acts as a secure Jump Host for SSH access.

---

## 🚀 One-Click Deployment

Everything is automated. You only need to run **one script**.

### Prerequisites
1.  **Terraform** installed.
2.  **GCP Credentials** configured (`gcloud auth application-default login`).
3.  **SSH Key** generated at `~/.ssh/id_rsa`.

### Step 1: Provision Infrastructure
```powershell
cd terraform
terraform init
terraform apply -auto-approve
cd ..
```

### Step 2: Deploy Software
Run the automated deployment script. This handles everything:
```powershell
.\DEPLOY.ps1
```
*This script uploads a deployment payload to the Load Balancer and orchestrates the installation of Nginx, Node.js, and PostgreSQL on all internal servers.*

---

## ✅ Verification

After deployment, the script will output the Load Balancer IP (e.g., `34.45.157.123`).

### 1. Public Access
Open your browser or run:
```powershell
curl http://<LOAD_BALANCER_IP>
```
*Expected Output:* `<h1>Web Server - web-server-X</h1>...`

### 2. Internal Connectivity Check
SSH into the Load Balancer to verify internal paths:
```bash
ssh ubuntu@<LOAD_BALANCER_IP>
```

From there, verify the chain:
```bash
# Check Web Server
curl http://10.0.2.2

# Check App Server (from Web Server)
ssh 10.0.2.2 "curl http://10.0.3.2:3000"

# Check Database (from App Server)
ssh 10.0.2.2 "ssh 10.0.3.2 'nc -zv 10.0.4.2 5432'"
```

---

## 🔧 Troubleshooting

### "502 Bad Gateway"
- **Cause**: Web Servers are not running Nginx or are unreachable.
- **Fix**: Re-run `.\DEPLOY.ps1` to ensure software is installed. Check `ssh ubuntu@10.0.2.2 "systemctl status nginx"`.

### "Connection Timed Out" during deployment
- **Cause**: Private instances cannot reach the internet.
- **Fix**: Ensure **Cloud NAT** is created in Terraform (`terraform/nat.tf`).

### SSH Permission Denied
- **Cause**: The Load Balancer doesn't have the SSH key.
- **Fix**: The `DEPLOY.ps1` script handles this, but you can manually fix it:
  ```powershell
  scp -i ~/.ssh/id_rsa ~/.ssh/id_rsa ubuntu@<LB_IP>:~/.ssh/
  ```

---

## 📂 Project Structure

```
├── DEPLOY.ps1                  # MAIN DEPLOYMENT SCRIPT
├── README.md                   # This documentation
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # VM definitions
│   ├── network.tf              # VPC & Subnets
│   ├── firewall.tf             # Security Rules
│   ├── nat.tf                  # Cloud NAT (Internet Access)
│   └── variables.tf            # Configuration
└── scripts/
    └── deploy-bulletproof.sh   # Internal deployment logic (runs on LB)
```
