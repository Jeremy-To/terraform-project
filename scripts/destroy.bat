@echo off
REM Infrastructure teardown script for Windows

setlocal

set PROJECT_ROOT=%~dp0..

echo ==========================================
echo 3-Tier Infrastructure Teardown
echo ==========================================
echo.

echo [WARNING] This will destroy all infrastructure!
set /p CONFIRM="Are you sure you want to continue? (yes/no): "

if /i not "%CONFIRM%"=="yes" (
    echo Teardown cancelled.
    exit /b 0
)

cd "%PROJECT_ROOT%\terraform"

echo [DESTROYING] Destroying infrastructure...
terraform destroy -auto-approve

echo.
echo ==========================================
echo [OK] Infrastructure destroyed successfully
echo ==========================================
echo.
echo Note: Packer images are NOT deleted. To delete them:
echo   gcloud compute images list --filter="name~web-server OR name~app-server OR name~db-server"
echo   gcloud compute images delete IMAGE_NAME
echo ==========================================

cd "%PROJECT_ROOT%"
