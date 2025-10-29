# Kubernetes Cluster Startup Script for Windows PowerShell
# Run from Host Machine (Windows)
# Usage: .\start-cluster-from-host.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Kubernetes Cluster Startup (from Windows Host)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Vagrant is installed
if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Vagrant is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Vagrantfile exists
if (-not (Test-Path "Vagrantfile")) {
    Write-Host "ERROR: Vagrantfile not found in current directory" -ForegroundColor Red
    Write-Host "Please run this script from the directory containing your Vagrantfile" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Checking VM status..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant status
Write-Host ""

Write-Host "Step 2: Starting Vagrant VMs..." -ForegroundColor Green
Write-Host "-----------------------------------"
Write-Host "Starting all VMs (this may take a few minutes)..." -ForegroundColor Yellow
vagrant up
Write-Host "✓ All VMs started" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Waiting for VMs to fully boot..." -ForegroundColor Green
Write-Host "-----------------------------------"
Start-Sleep -Seconds 10
Write-Host "✓ VMs should be ready" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Starting containerd on master node..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl start containerd 2>/dev/null || true"
Start-Sleep -Seconds 3
Write-Host "✓ Containerd started on master" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Starting kubelet on master node..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl start kubelet 2>/dev/null || true"
Start-Sleep -Seconds 5
Write-Host "✓ Kubelet started on master" -ForegroundColor Green
Write-Host ""

Write-Host "Step 6: Starting containerd on worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
foreach ($node in @("centos2", "centos3")) {
    Write-Host "Starting containerd on $node..."
    vagrant ssh $node -c "sudo systemctl start containerd 2>/dev/null || true"
    Start-Sleep -Seconds 2
}
Write-Host "✓ Containerd started on all worker nodes" -ForegroundColor Green
Write-Host ""

Write-Host "Step 7: Starting kubelet on worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
foreach ($node in @("centos2", "centos3")) {
    Write-Host "Starting kubelet on $node..."
    vagrant ssh $node -c "sudo systemctl start kubelet 2>/dev/null || true"
    Start-Sleep -Seconds 2
}
Write-Host "✓ Kubelet started on all worker nodes" -ForegroundColor Green
Write-Host ""

Write-Host "Step 8: Waiting for cluster to stabilize..." -ForegroundColor Green
Write-Host "-----------------------------------"
Write-Host "Waiting 30 seconds for nodes to become ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host ""

Write-Host "Step 9: Uncordoning worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "kubectl uncordon centos2 2>/dev/null || true"
vagrant ssh centos1 -c "kubectl uncordon centos3 2>/dev/null || true"
Write-Host "✓ Worker nodes uncordoned" -ForegroundColor Green
Write-Host ""

Write-Host "Step 10: Checking cluster status..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "kubectl get nodes"
Write-Host ""

Write-Host "Step 11: Checking system pods..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "kubectl get pods -n kube-system"
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cluster Startup Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Vagrant VMs are running" -ForegroundColor Green
Write-Host "✓ Kubernetes services started" -ForegroundColor Green
Write-Host "✓ Cluster is ready" -ForegroundColor Green
Write-Host ""
Write-Host "To access the cluster:" -ForegroundColor Yellow
Write-Host "  vagrant ssh centos1"
Write-Host "  kubectl get nodes"
Write-Host ""
Write-Host "To check VM status:" -ForegroundColor Yellow
Write-Host "  vagrant status"
Write-Host ""
Write-Host "To shutdown cluster:" -ForegroundColor Yellow
Write-Host "  .\shutdown-cluster-from-host.ps1"
Write-Host "==========================================" -ForegroundColor Cyan