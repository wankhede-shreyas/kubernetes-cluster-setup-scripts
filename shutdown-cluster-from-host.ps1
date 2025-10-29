# Kubernetes Cluster Shutdown Script for Windows PowerShell
# Run from Host Machine (Windows)
# Usage: .\shutdown-cluster-from-host.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Kubernetes Cluster Shutdown (from Windows Host)" -ForegroundColor Cyan
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

# Check if VMs are running
$vmStatus = vagrant status | Select-String "centos[1-3].*running"
if (-not $vmStatus) {
    Write-Host "⚠ No VMs are currently running" -ForegroundColor Yellow
    Write-Host "Nothing to shutdown" -ForegroundColor Yellow
    exit 0
}

Write-Host "Step 2: Checking cluster status..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "kubectl get nodes 2>/dev/null || echo 'Could not connect to cluster'"
Write-Host ""

Write-Host "Step 3: Draining worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
foreach ($node in @("centos2", "centos3")) {
    Write-Host "Draining $node..." -ForegroundColor Yellow
    vagrant ssh centos1 -c "kubectl drain $node --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 --timeout=2m 2>/dev/null || echo 'Could not drain $node'"
}
Write-Host ""

Write-Host "Step 4: Stopping kubelet on worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
foreach ($node in @("centos2", "centos3")) {
    Write-Host "Stopping kubelet on $node..."
    vagrant ssh $node -c "sudo systemctl stop kubelet 2>/dev/null || true"
}
Write-Host ""

Write-Host "Step 5: Stopping containerd on worker nodes..." -ForegroundColor Green
Write-Host "-----------------------------------"
foreach ($node in @("centos2", "centos3")) {
    Write-Host "Stopping containerd on $node..."
    vagrant ssh $node -c "sudo systemctl stop containerd 2>/dev/null || true"
}
Write-Host ""

Write-Host "Step 6: Stopping kubelet on master node..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl stop kubelet 2>/dev/null || true"
Write-Host ""

Write-Host "Step 7: Stopping containerd on master node..." -ForegroundColor Green
Write-Host "-----------------------------------"
vagrant ssh centos1 -c "sudo systemctl stop containerd 2>/dev/null || true"
Write-Host ""

Write-Host "Step 8: Shutting down Vagrant VMs..." -ForegroundColor Green
Write-Host "-----------------------------------"
Write-Host "Halting all VMs (this may take a minute)..." -ForegroundColor Yellow
vagrant halt
Write-Host "✓ All VMs halted" -ForegroundColor Green
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cluster Shutdown Complete!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Kubernetes services stopped" -ForegroundColor Green
Write-Host "✓ Vagrant VMs halted" -ForegroundColor Green
Write-Host ""
Write-Host "To start the cluster again:" -ForegroundColor Yellow
Write-Host "  .\start-cluster-from-host.ps1"
Write-Host ""
Write-Host "To completely destroy VMs (WARNING: deletes everything):" -ForegroundColor Yellow
Write-Host "  vagrant destroy -f"
Write-Host ""
Write-Host "To check VM status:" -ForegroundColor Yellow
Write-Host "  vagrant status"
Write-Host "==========================================" -ForegroundColor Cyan