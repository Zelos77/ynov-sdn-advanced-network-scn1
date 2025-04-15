#!/bin/bash
source /vagrant/scripts/common.sh

# === 1. Installer FRRouting ===
sudo apt-get install -y frr

# === 2. Activer OSPF dans les daemons ===
sudo sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons
sudo systemctl restart frr

# === 3. Déployer la configuration FRR spécifique ===
HOST=$(hostname)
sudo cp /vagrant/configs/${HOST}-frr.conf /etc/frr/frr.conf
sudo chown frr:frr /etc/frr/frr.conf
sudo systemctl restart frr

# === 4. Installer frr_exporter version compatible (avec --frr.vtysh) ===
VERSION="1.0.0"
cd /tmp
wget https://github.com/tynany/frr_exporter/releases/download/v${VERSION}/frr_exporter-${VERSION}.linux-amd64.tar.gz
tar xvf frr_exporter-${VERSION}.linux-amd64.tar.gz
sudo cp frr_exporter-${VERSION}.linux-amd64/frr_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/frr_exporter

# === 5. Ajouter frr au groupe frrvty pour accéder à vtysh ===
sudo usermod -aG frrvty frr

# === 6. Créer le service systemd frr_exporter avec --frr.vtysh activé ===
cat <<EOF | sudo tee /etc/systemd/system/frr_exporter.service
[Unit]
Description=FRR Exporter (vtysh mode)
After=network.target

[Service]
User=frr
Group=frr
ExecStart=/usr/local/bin/frr_exporter \\
  --frr.vtysh \\
  --frr.vtysh.path="/usr/bin/vtysh" \\
  --web.listen-address=":9122"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 7. Activer et lancer le service ===
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now frr_exporter

# === 8. Test local de metrics ===
echo -e "\n[INFO] Test de métriques OSPF :"
curl -s http://localhost:9122/metrics | grep ospf | head -n 5 || echo "❌ frr_exporter ne répond pas"
