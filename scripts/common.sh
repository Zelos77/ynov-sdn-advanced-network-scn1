#!/bin/bash
# Script commun exécuté sur toutes les machines - Les EOL Sequence doivent etre en LF

## 1. Configuration des permissions
echo "vagrant ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/vagrant
sudo chmod 440 /etc/sudoers.d/vagrant

## 2. Mise à jour du système
sudo apt-get update -qq && sudo apt-get upgrade -y -qq

## 3. Installation des dépendances communes
sudo apt-get install -y -qq \
    net-tools \
    curl \
    wget \
    tcpdump \
    traceroute \
    python3-pip

## 4. Configuration du timezone (évite les prompts interactifs)
sudo timedatectl set-timezone Europe/Paris

## 5. Configuration réseau de base
cat <<EOF | sudo tee /etc/sysctl.d/10-network.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
sudo sysctl -p /etc/sysctl.d/10-network.conf

## 6. Installation et configuration de Node Exporter
sudo apt-get install -y -qq prometheus-node-exporter

# Modifier le fichier de service pour écouter sur toutes les interfaces
sudo sed -i 's/127.0.0.1:9100/0.0.0.0:9100/' /etc/default/prometheus-node-exporter

# Redémarrer le service
sudo systemctl enable --now prometheus-node-exporter
sudo systemctl restart prometheus-node-exporter

## 7. Optimisations système
# Désactiver le swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Augmenter les limites de fichiers
cat <<EOF | sudo tee -a /etc/security/limits.conf
* soft nofile 65536
* hard nofile 131072
* soft nproc 65536
* hard nproc 65536
EOF

## 8. Configuration SSH (pour accès plus rapide)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

## 9. Journalisation centralisée (optionnel)
sudo apt-get install -y -qq rsyslog
cat <<EOF | sudo tee /etc/rsyslog.d/10-remote.conf
*.* @192.168.100.10:514
EOF
sudo systemctl restart rsyslog

## 10. NTP pour la synchronisation horaire
sudo apt-get install -y -qq chrony
sudo systemctl enable --now chrony