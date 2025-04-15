#!/bin/bash

OUT="/vagrant/tests/report-$(hostname).txt"
mkdir -p /vagrant/tests
echo "=== RAPPORT DE TEST - $(hostname) ===" > "$OUT"
echo "Date : $(date)" >> "$OUT"

echo -e "\n--- Interfaces réseau (ip a) ---" >> "$OUT"
ip a >> "$OUT"

echo -e "\n--- Routes (ip route) ---" >> "$OUT"
ip route >> "$OUT"

echo -e "\n--- Services FRR & Exporter ---" >> "$OUT"
systemctl is-active frr >> "$OUT"
systemctl is-active frr_exporter >> "$OUT" 2>/dev/null

echo -e "\n--- Présence du binaire vtysh ---" >> "$OUT"
which vtysh >> "$OUT" || echo "vtysh absent" >> "$OUT"

echo -e "\n--- Routes OSPF (si FRR présent) ---" >> "$OUT"
if command -v vtysh &> /dev/null; then
    vtysh -c "show ip ospf" >> "$OUT" 2>&1
    vtysh -c "show ip ospf neighbor" >> "$OUT" 2>&1
    if vtysh -c "show ip ospf neighbor" | grep -q Full; then
        echo "✔ OSPF fonctionne : voisinage établi" >> "$OUT"
    else
        echo "⚠️ OSPF actif mais pas de voisin en Full" >> "$OUT"
    fi
else
    echo "❌ vtysh indisponible, pas d'OSPF détecté" >> "$OUT"
fi

echo -e "\n--- Test curl Prometheus exporter (localhost:9122) ---" >> "$OUT"
curl -s http://localhost:9122/metrics | grep ospf | head -n 10 >> "$OUT" || echo "Exporter KO" >> "$OUT"

echo -e "\n--- Open vSwitch (si présent) ---" >> "$OUT"
command -v ovs-vsctl &> /dev/null && ovs-vsctl show >> "$OUT" || echo "OVS non installé" >> "$OUT"

echo -e "\n--- Services supervisés ---" >> "$OUT"
systemctl --type=service --state=running | grep -E 'frr|ryu|prometheus|grafana|node-exporter' >> "$OUT"

echo -e "\n--- Variables d’environnement réseau ---" >> "$OUT"
sysctl net.ipv4.ip_forward >> "$OUT"
sysctl net.ipv6.conf.all.disable_ipv6 >> "$OUT"

echo "[✔] Rapport détaillé généré dans $OUT"
