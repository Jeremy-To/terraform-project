# Infrastructure 3-Tiers sur GCP

Une infrastructure 3-tiers de qualité production, entièrement automatisée et déployée sur Google Cloud Platform via Terraform et PowerShell.

## 🏗️ Architecture

L'infrastructure se compose de **7 Machines Virtuelles** réparties dans 4 sous-réseaux pour une sécurité maximale :

| Tier | Composant | Qté | Plage IP | Description |
|------|-----------|-----|----------|-------------|
| **Public** | **Load Balancer** | 1 | `34.x.x.x` | Bastion Nginx & Reverse Proxy. Point d'entrée unique. |
| **Web** | **Serveurs Web** | 2 | `10.0.2.x` | Serveurs Web Nginx servant le contenu statique. |
| **App** | **Serveurs App** | 2 | `10.0.3.x` | Serveurs API Node.js (gérés par PM2). |
| **DB** | **Bases de Données** | 2 | `10.0.4.x` | Cluster PostgreSQL Maître/Réplique. |

### Fonctionnalités de Sécurité
- **Cloud NAT** : Permet aux instances privées d'installer des mises à jour sans avoir d'IP publique.
- **Pare-feu** : Règles strictes. Le LB ne peut atteindre que le Web. Le Web ne peut atteindre que l'App. L'App ne peut atteindre que la DB.
- **Hôte Bastion** : Le Load Balancer agit comme un point d'accès SSH sécurisé (Jump Host).

---

## 🚀 Déploiement en un Clic

Tout est automatisé. Vous n'avez besoin d'exécuter qu'**un seul script**.

### Prérequis
1.  **Terraform** installé.
2.  **Identifiants GCP** configurés (`gcloud auth application-default login`).
3.  **Clé SSH** générée dans `~/.ssh/id_rsa`.

### Étape 1 : Provisionner l'Infrastructure
```powershell
cd terraform
terraform init
terraform apply -auto-approve
cd ..
```

### Étape 2 : Déployer les Logiciels
Exécutez le script de déploiement automatisé. Il gère tout :
```powershell
.\DEPLOY.ps1
```
*Ce script télécharge une charge utile de déploiement sur le Load Balancer et orchestre l'installation de Nginx, Node.js et PostgreSQL sur tous les serveurs internes.*

---

## ✅ Vérification

Après le déploiement, le script affichera l'IP du Load Balancer (ex: `34.45.157.123`).

### 1. Accès Public
Ouvrez votre navigateur ou exécutez :
```powershell
curl http://<IP_LOAD_BALANCER>
```
*Résultat attendu :* `<h1>Web Server - web-server-X</h1>...`

### 2. Vérification de la Connectivité Interne
Connectez-vous en SSH au Load Balancer pour vérifier les chemins internes :
```bash
ssh ubuntu@<IP_LOAD_BALANCER>
```

Depuis là, vérifiez la chaîne de connexion :
```bash
# Vérifier le Serveur Web
curl http://10.0.2.2

# Vérifier le Serveur App (depuis le Serveur Web)
ssh 10.0.2.2 "curl http://10.0.3.2:3000"

# Vérifier la Base de Données (depuis le Serveur App)
ssh 10.0.2.2 "ssh 10.0.3.2 'nc -zv 10.0.4.2 5432'"
```

---

## 🔧 Dépannage

### "502 Bad Gateway"
- **Cause** : Les serveurs Web ne font pas tourner Nginx ou sont inaccessibles.
- **Solution** : Relancez `.\DEPLOY.ps1` pour vous assurer que les logiciels sont installés. Vérifiez avec `ssh ubuntu@10.0.2.2 "systemctl status nginx"`.

### "Connection Timed Out" pendant le déploiement
- **Cause** : Les instances privées ne peuvent pas atteindre Internet.
- **Solution** : Assurez-vous que le **Cloud NAT** est créé dans Terraform (`terraform/nat.tf`).

### SSH Permission Denied
- **Cause** : Le Load Balancer n'a pas la clé SSH.
- **Solution** : Le script `DEPLOY.ps1` gère cela, mais vous pouvez le corriger manuellement :
  ```powershell
  scp -i ~/.ssh/id_rsa ~/.ssh/id_rsa ubuntu@<IP_LB>:~/.ssh/
  ```

---

## 📂 Structure du Projet

```
├── DEPLOY.ps1                  # SCRIPT DE DÉPLOIEMENT PRINCIPAL
├── README.md                   # Cette documentation
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Définitions des VMs
│   ├── network.tf              # VPC & Sous-réseaux
│   ├── firewall.tf             # Règles de sécurité
│   ├── nat.tf                  # Cloud NAT (Accès Internet)
│   └── variables.tf            # Configuration
└── scripts/
    └── deploy-bulletproof.sh   # Logique interne de déploiement (exécutée sur le LB)
```
