#!/bin/bash
source /vagrant/scripts/common.sh

# Les EOL Sequence doivent etre en LF

# === 1. Installation de Ryu, OVS, dépendances ===
sudo apt-get install -y \
    openvswitch-switch \
    python3-ryu \
    net-tools \
    curl \
    software-properties-common \
    gnupg2

# === 2. Configuration d'Open vSwitch ===
#sudo ovs-vsctl add-br br0
#sudo ovs-vsctl add-port br0 enp0s8
#sudo ovs-vsctl set-controller br0 tcp:192.168.100.10:6633
#sudo ovs-vsctl set-fail-mode br0 secure

# === 3. Installation de Grafana depuis le dépôt officiel ===
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/grafana.gpg

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt-get update
sudo apt-get install -y grafana

# === 4. Démarrage de Grafana ===
sudo systemctl enable --now grafana-server

# === 5. Installation manuelle de Prometheus ===
cd /tmp
PROM_VERSION="2.51.0"
wget https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-amd64.tar.gz
tar xvf prometheus-$PROM_VERSION.linux-amd64.tar.gz
cd prometheus-$PROM_VERSION.linux-amd64

sudo mv prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo cp -r consoles console_libraries /etc/prometheus

# === 6. Configuration Prometheus ===
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'frr'
    static_configs:
      - targets: ['192.168.100.21:9122', '192.168.100.22:9122']
  - job_name: 'nodes'
    static_configs:
      - targets: ['192.168.100.10:9100', '192.168.100.21:9100', '192.168.100.22:9100', '192.168.100.30:9100']
EOF

# === 7. Création service systemd pour Prometheus ===
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOF

# === 8. Démarrage Prometheus ===
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# === 9. Lancement du contrôleur Ryu avec redirection HTTP ===
nohup sudo ryu-manager /vagrant/ryu-apps/http_redirect.py > /var/log/ryu.log 2>&1 &
