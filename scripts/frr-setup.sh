#!/bin/bash
source /vagrant/scripts/common.sh

# === 1. Installer FRRouting ===
sudo apt-get install -y frr

# === 2. Activer OSPF ===
sudo sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
sudo systemctl restart frr

# === 3. Déployer la configuration OSPF ===
HOST=$(hostname)
sudo cp /vagrant/configs/${HOST}-frr.conf /etc/frr/frr.conf
sudo chown frr:frr /etc/frr/frr.conf
sudo chmod 640 /etc/frr/frr.conf

# === 4. Fixer les droits de vtysh.conf ===
sudo touch /etc/frr/vtysh.conf
sudo chown frr:frr /etc/frr/vtysh.conf
sudo chmod 640 /etc/frr/vtysh.conf

# === 5. Redémarrer FRR ===
sudo systemctl restart frr

# === 6. Installer frr_exporter compatible (v1.0.0) ===
VERSION="1.0.0"
cd /tmp
wget https://github.com/tynany/frr_exporter/releases/download/v${VERSION}/frr_exporter-${VERSION}.linux-amd64.tar.gz
tar xvf frr_exporter-${VERSION}.linux-amd64.tar.gz
sudo cp frr_exporter-${VERSION}.linux-amd64/frr_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/frr_exporter

# === 7. Ajouter frr au groupe frrvty ===
sudo usermod -aG frrvty frr

# === 8. Créer le service systemd ===
cat <<EOF | sudo tee /etc/systemd/system/frr_exporter.service
[Unit]
Description=FRR Exporter (vtysh mode)
After=network.target

[Service]
User=frr
Group=frr
ExecStart=/usr/local/bin/frr_exporter \
  --frr.vtysh \
  --frr.vtysh.path="/usr/bin/vtysh" \
  --web.listen-address=":9122"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 9. Activer et démarrer l'exporter ===
sudo systemctl daemon-reload
sudo systemctl enable --now frr_exporter

# === 10. Test Prometheus local ===
echo "[INFO] Test Prometheus exporter :"
curl -s http://localhost:9122/metrics | grep ospf | head -n 5 || echo "❌ Exporter ne répond pas"
