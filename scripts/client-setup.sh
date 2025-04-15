#!/bin/bash
# Script de configuration des machines clientes - Les EOL Sequence doivent etre en LF

# Charger la configuration commune
source /vagrant/scripts/common.sh

## 1. Installation des outils réseaux et de test
sudo apt-get install -y -qq \
    iperf3 \
    htop \
    iftop \
    jq \
    httpie \
    dnsutils \
    nmap \
    netcat-openbsd

## 2. Configuration réseau persistante
cat <<EOF | sudo tee /etc/netplan/99-vagrant.yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses: [$(hostname -I | awk '{print $2}')/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
sudo netplan apply

## 3. Configuration des alias utiles
cat <<EOF >> ~/.bashrc
# Alias réseaux
alias netsum='ip -br -c a'
alias routes='ip -c route'
alias ospfcheck='vtysh -c "show ip ospf neighbor" 2>/dev/null || echo "OSPF non configuré"'
alias flows='sudo ovs-ofctl dump-flows br0 2>/dev/null || echo "OVS non configuré"'
EOF

## 4. Déploiement des scripts de test
sudo mkdir -p /opt/net-tests

# Script de test de connectivité de base
cat <<EOF | sudo tee /opt/net-tests/basic_test.sh
#!/bin/bash
echo "\n=== Test de connectivité ==="
ping -c 4 192.168.100.10 && echo "OK: Contrôleur accessible" || echo "ERREUR: Problème de connexion"
ping -c 4 192.168.100.21 && echo "OK: Router1 accessible" || echo "ERREUR: Problème de connexion"
ping -c 4 192.168.100.22 && echo "OK: Router2 accessible" || echo "ERREUR: Problème de connexion"

echo "\n=== Test HTTP ==="
curl -Is http://192.168.100.10:3000 | head -1 && echo "OK: Grafana accessible" || echo "ERREUR: Service Grafana"

echo "\n=== Test OSPF (via FRR Exporter) ==="
curl -s http://192.168.100.21:9122/metrics | grep ospf && echo "OK: Métriques OSPF trouvées" || echo "ERREUR: Exporter FRR"
EOF
sudo chmod +x /opt/net-tests/basic_test.sh

## 5. Configuration du monitoring avancé
# Installation de Telegraf pour les métriques supplémentaires
wget -q https://dl.influxdata.com/telegraf/releases/telegraf_1.24.4-1_amd64.deb
sudo dpkg -i telegraf_*.deb
rm telegraf_*.deb

# Configuration Telegraf pour Prometheus
cat <<EOF | sudo tee /etc/telegraf/telegraf.conf
[agent]
  interval = "10s"
  flush_interval = "10s"

[[outputs.prometheus_client]]
  listen = ":9273"
  metric_version = 2

[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.mem]]
[[inputs.disk]]
[[inputs.net]]
EOF

sudo systemctl enable --now telegraf

## 6. Personnalisation de l'environnement
# Message de bienvenue
cat <<EOF | sudo tee /etc/motd

=== Lab SDN ===
Machine: $(hostname)
IP: $(hostname -I | awk '{print $2}')
Rôle: Machine cliente
Commandes utiles:
- /opt/net-tests/basic_test.sh
- netsum / routes / ospfcheck
EOF

## 7. Nettoyage final
sudo apt-get autoremove -y -qq