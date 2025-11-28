@echo off
REM Windows deployment script for 3-tier infrastructure
REM This script orchestrates Packer, Terraform, and Ansible (via Docker)

setlocal enabledelayedexpansion

echo ==========================================
echo 3-Tier Infrastructure Deployment
echo ==========================================
echo.

set START_TIME=%TIME%
set PROJECT_ROOT=%~dp0..

REM Step 1: Build Packer Images
echo ==^> Step 1: Building Packer Images (Skip if already built)
set /p BUILD_IMAGES="Do you want to build Packer images? (y/n) [Default: n]: "
if /i "%BUILD_IMAGES%"=="y" (
    cd "%PROJECT_ROOT%\packer"
    
    echo ==^> Building Web Server Image...
    packer build -var-file=variables.auto.pkrvars.hcl web-server.pkr.hcl
    if errorlevel 1 (
        echo [ERROR] Web server image build failed
        exit /b 1
    )
    echo [OK] Web server image built
    
    echo ==^> Building App Server Image...
    packer build -var-file=variables.auto.pkrvars.hcl app-server.pkr.hcl
    if errorlevel 1 (
        echo [ERROR] App server image build failed
        exit /b 1
    )
    echo [OK] App server image built
    
    echo ==^> Building Database Server Image...
    packer build -var-file=variables.auto.pkrvars.hcl db-server.pkr.hcl
    if errorlevel 1 (
        echo [ERROR] Database server image build failed
        exit /b 1
    )
    echo [OK] Database server image built
) else (
    echo Skipping Packer image build...
)

REM Step 2: Initialize and Apply Terraform
echo.
echo ==^> Step 2: Provisioning Infrastructure with Terraform
cd "%PROJECT_ROOT%\terraform"

echo ==^> Initializing Terraform...
terraform init
if errorlevel 1 (
    echo [ERROR] Terraform init failed
    exit /b 1
)
echo [OK] Terraform initialized

echo ==^> Validating Terraform configuration...
terraform validate
if errorlevel 1 (
    echo [ERROR] Terraform validation failed
    exit /b 1
)
echo [OK] Terraform configuration valid

echo ==^> Planning Terraform deployment...
terraform plan -out=tfplan
if errorlevel 1 (
    echo [ERROR] Terraform plan failed
    exit /b 1
)
echo [OK] Terraform plan created

echo ==^> Applying Terraform configuration...
terraform apply tfplan
if errorlevel 1 (
    echo [ERROR] Terraform apply failed
    exit /b 1
)
echo [OK] Infrastructure provisioned

REM Step 3: Generate Ansible Inventory
echo.
echo ==^> Step 3: Generating Ansible Inventory
terraform output -raw ansible_inventory > "%PROJECT_ROOT%\ansible\inventory\hosts"
if errorlevel 1 (
    echo [ERROR] Failed to generate Ansible inventory
    exit /b 1
)
echo [OK] Ansible inventory generated

REM Get load balancer IP for display
for /f "delims=" %%i in ('terraform output -raw load_balancer_ip') do set LB_IP=%%i
echo [OK] Load Balancer IP: %LB_IP%

REM Step 4: Wait for instances to be ready
echo.
echo ==^> Step 4: Waiting for instances to be ready...
echo Waiting 60 seconds for SSH to be available...
timeout /t 60 /nobreak >nul
echo [OK] Instances should be ready

REM Step 5: Run Ansible Deployment
echo.
echo ==^> Step 5: Deploying Application with Ansible
cd "%PROJECT_ROOT%\ansible"

echo ==^> Testing Ansible connectivity...
docker run --rm -v "%cd%:/ansible" -v "%USERPROFILE%\.ssh:/root/.ssh:ro" -w /ansible cytopia/ansible:latest-tools ansible all -m ping -i inventory/hosts
if errorlevel 1 (
    echo [WARN] Ansible connectivity test failed. Waiting additional 30 seconds...
    timeout /t 30 /nobreak >nul
    docker run --rm -v "%cd%:/ansible" -v "%USERPROFILE%\.ssh:/root/.ssh:ro" -w /ansible cytopia/ansible:latest-tools ansible all -m ping -i inventory/hosts
)
echo [OK] Ansible connectivity established

echo ==^> Running Ansible playbook...
docker run --rm -v "%cd%:/ansible" -v "%USERPROFILE%\.ssh:/root/.ssh:ro" -w /ansible cytopia/ansible:latest-tools ansible-playbook -i inventory/hosts playbooks/deploy.yml
if errorlevel 1 (
    echo [ERROR] Ansible playbook failed
    exit /b 1
)
echo [OK] Application deployed

REM Calculate deployment time
set END_TIME=%TIME%
echo.
echo ==========================================
echo [OK] DEPLOYMENT COMPLETE!
echo ==========================================
echo.
echo Access your application at: http://%LB_IP%
echo.
echo SSH to load balancer: ssh ubuntu@%LB_IP%
echo.
echo To destroy infrastructure, run: scripts\destroy.bat
echo ==========================================

cd "%PROJECT_ROOT%"
