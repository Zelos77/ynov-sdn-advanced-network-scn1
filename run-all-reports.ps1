# run-all-reports.ps1 WORK IN PROGRESS

$VMs = @("router1", "router2", "ryu", "client1")
Write-Host "[INFO] Génération des rapports sur toutes les VMs..."

foreach ($vm in $VMs) {
    Write-Host "▶ Génération sur $vm"
    vagrant ssh $vm -c "/vagrant/scripts/generate-report.sh"
}

Write-Host "[OK] Tous les rapports ont été générés dans le dossier /tests"
