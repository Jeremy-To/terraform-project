@echo off
REM Health check script for Windows

setlocal

set PROJECT_ROOT=%~dp0..

echo ==========================================
echo 3-Tier Infrastructure Health Check
echo ==========================================
echo.

cd "%PROJECT_ROOT%\terraform"

REM Get IPs from Terraform
for /f "delims=" %%i in ('terraform output -raw load_balancer_ip 2^>nul') do set LB_IP=%%i

if "%LB_IP%"=="" (
    echo [ERROR] Could not retrieve load balancer IP
    exit /b 1
)

echo Load Balancer IP: %LB_IP%
echo.

REM Test 1: Load Balancer HTTP
echo Testing Load Balancer HTTP response...
curl -s -o nul -w "%%{http_code}" http://%LB_IP% | findstr "200" >nul
if errorlevel 1 (
    echo [FAIL] Load Balancer HTTP test failed
) else (
    echo [PASS] Load Balancer HTTP test passed
)

REM Test 2: Load Balancer Health Endpoint
echo Testing Load Balancer health endpoint...
curl -s http://%LB_IP%/health | findstr "healthy" >nul
if errorlevel 1 (
    echo [FAIL] Load Balancer health endpoint test failed
) else (
    echo [PASS] Load Balancer health endpoint test passed
)

REM Test 3: API Health
echo Testing API health endpoint...
curl -s http://%LB_IP%/api/health | findstr "healthy" >nul
if errorlevel 1 (
    echo [FAIL] API health endpoint test failed
) else (
    echo [PASS] API health endpoint test passed
)

REM Test 4: Database Connectivity
echo Testing database connectivity via API...
curl -s http://%LB_IP%/api/health | findstr "connected" >nul
if errorlevel 1 (
    echo [FAIL] Database connectivity test failed
) else (
    echo [PASS] Database connectivity test passed
)

REM Test 5: API Data endpoint
echo Testing API data endpoint...
curl -s http://%LB_IP%/api/data | findstr "success" >nul
if errorlevel 1 (
    echo [FAIL] API data endpoint test failed
) else (
    echo [PASS] API data endpoint test passed
)

echo.
echo ==========================================
echo Health Check Complete
echo ==========================================
echo.
echo Access the application at: http://%LB_IP%
echo.

cd "%PROJECT_ROOT%"
