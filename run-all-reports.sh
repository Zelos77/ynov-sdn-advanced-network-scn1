#!/bin/bash  WORK IN PROGRESS

# Liste des VMs pour lesquelles générer un rapport
vms=("router1" "router2" "ryu" "client1")

echo "[INFO] Génération des rapports de test sur toutes les VMs..."

for vm in "${vms[@]}"; do
  echo "▶ Génération sur $vm"
  vagrant ssh "$vm" -c "/vagrant/scripts/generate-report.sh"
done

echo "[✔] Tous les rapports ont été générés dans le dossier /tests"
