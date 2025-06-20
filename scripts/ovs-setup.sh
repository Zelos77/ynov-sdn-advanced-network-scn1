#!/bin/bash

set -e

echo "[+] Démarrage du script ovs-setup.sh"

# Installation d'Open vSwitch
echo "[+] Installation d'Open vSwitch"
sudo apt update
sudo apt install -y openvswitch-switch

# Création du bridge OVS
echo "[+] Création du bridge OVS : br0"
if ! sudo ovs-vsctl br-exists br0; then
  sudo ovs-vsctl add-br br0
else
  echo "[i] Le bridge br0 existe déjà"
fi

# Interface à ajouter au bridge
INTERFACE="enp0s8"

# Vérification de l'existence de l'interface réseau
if ip link show "$INTERFACE" > /dev/null 2>&1; then
  echo "[+] Ajout de l'interface $INTERFACE au bridge br0"
  sudo ovs-vsctl add-port br0 "$INTERFACE" || echo "[i] $INTERFACE déjà connectée"
else
  echo "[!] Interface $INTERFACE non trouvée. Aucun port ajouté au bridge."
fi

# Définition du contrôleur Ryu
RYU_CONTROLLER_IP="192.168.100.10"
echo "[+] Liaison du bridge OVS au contrôleur Ryu ($RYU_CONTROLLER_IP:6633)"
sudo ovs-vsctl set-controller br0 tcp:$RYU_CONTROLLER_IP:6633

# Mode sécurisé
sudo ovs-vsctl set-fail-mode br0 secure

# Affichage de la config
echo "[+] Configuration actuelle du bridge :"
sudo ovs-vsctl show

echo "[✓] Open vSwitch configuré avec succès sur $(hostname)"
