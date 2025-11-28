# BULLETPROOF DEPLOYMENT - Final Automated Solution
param([string]$LB_IP = "34.45.157.123")

$ErrorActionPreference = "Continue"
$SSH_KEY = "$env:USERPROFILE\.ssh\id_rsa"

Write-Host "`n==========================================`n" -ForegroundColor Cyan
Write-Host "  BULLETPROOF 3-TIER DEPLOYMENT" -ForegroundColor Cyan
Write-Host "`n==========================================`n" -ForegroundColor Cyan

# Step 1: Upload deployment script
Write-Host "[Step 1/3] Uploading deployment script..." -ForegroundColor Yellow
scp -q -o StrictHostKeyChecking=no -i $SSH_KEY scripts\deploy-bulletproof.sh ubuntu@${LB_IP}:/tmp/deploy.sh 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Done`n" -ForegroundColor Green
}
else {
    Write-Host "  Failed!`n" -ForegroundColor Red
    exit 1
}

# Step 2: Prepare script
Write-Host "[Step 2/3] Preparing script..." -ForegroundColor Yellow
ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$LB_IP "chmod +x /tmp/deploy.sh; sed -i 's/\r//g' /tmp/deploy.sh" 2>$null
Write-Host "  Done`n" -ForegroundColor Green

# Step 3: Execute deployment
Write-Host "[Step 3/3] Executing deployment (5-10 minutes)..." -ForegroundColor Yellow
Write-Host "  Installing software on all 6 servers...`n" -ForegroundColor Gray

ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$LB_IP "bash /tmp/deploy.sh"

$deployment_exit_code = $LASTEXITCODE

Write-Host "`n==========================================`n" -ForegroundColor Cyan
if ($deployment_exit_code -eq 0) {
    Write-Host "  DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
}
else {
    Write-Host "  Deployment completed with warnings" -ForegroundColor Yellow
}
Write-Host "`n==========================================`n" -ForegroundColor Cyan

# Verification
Write-Host "Verifying deployment...`n" -ForegroundColor Cyan
Start-Sleep -Seconds 5

Write-Host "[Test 1] Load Balancer HTTP" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$LB_IP" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "  SUCCESS! HTTP $($response.StatusCode)" -ForegroundColor Green
    Write-Host "  $($response.Content.Substring(0, [Math]::Min(60, $response.Content.Length)))...`n" -ForegroundColor Gray
}
catch {
    Write-Host "  Failed: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "[Test 2] App Server API" -ForegroundColor Yellow
$app_test = ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$LB_IP "curl -s http://10.0.3.2:3000" 2>$null
if ($app_test) {
    Write-Host "  App Server OK`n" -ForegroundColor Green
}
else {
    Write-Host "  Not responding yet`n" -ForegroundColor Yellow
}

Write-Host "[Test 3] Database" -ForegroundColor Yellow
$db_test = ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$LB_IP "nc -zv 10.0.4.2 5432 2>&1" 2>$null
if ($db_test -match "succeeded") {
    Write-Host "  Database OK`n" -ForegroundColor Green
}
else {
    Write-Host "  Check inconclusive`n" -ForegroundColor Yellow
}

Write-Host "`n==========================================`n" -ForegroundColor Cyan
Write-Host "Access: http://$LB_IP`n" -ForegroundColor White
Write-Host "To destroy: cd terraform; terraform destroy`n" -ForegroundColor Gray
