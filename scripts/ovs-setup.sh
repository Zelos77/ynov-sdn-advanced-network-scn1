#!/bin/bash

# Mettre à jour les paquets et installer Open vSwitch
sudo apt update
sudo apt install -y openvswitch-switch

# Créer le bridge br0 s'il n'existe pas déjà
if ! sudo ovs-vsctl br-exists br0; then
    echo "[+] Création du bridge br0"
    sudo ovs-vsctl add-br br0
else
    echo "[=] Le bridge br0 existe déjà"
fi

# Ajouter l'interface physique enp0s8 au bridge s'il n'est pas encore présent
if ! sudo ovs-vsctl list-ports br0 | grep -q enp0s8; then
    echo "[+] Ajout de l'interface enp0s8 au bridge br0"
    sudo ovs-vsctl add-port br0 enp0s8
else
    echo "[=] L'interface enp0s8 est déjà présente dans br0"
fi

# Récupérer l'adresse IP actuelle de enp0s8 et la gateway
IP=$(ip -4 -o addr show enp0s8 | awk '{print $4}')
GW=$(ip route show default | awk '/default/ {print $3}')

echo "[*] Adresse IP détectée sur enp0s8 : $IP"
echo "[*] Gateway détectée : $GW"

# Désactiver l'IP de enp0s8 et la transférer vers br0
if [ -n "$IP" ]; then
    echo "[+] Transfert de l'IP de enp0s8 vers br0"
    sudo ip addr flush dev enp0s8
    sudo ip addr add "$IP" dev br0
    sudo ip link set dev br0 up

    # Supprimer puis rétablir la route par défaut
    sudo ip route del default || true
    sudo ip route add default via "$GW"
else
    echo "[!] Aucune adresse IP détectée sur enp0s8, vérifiez la configuration"
fi

# Affichage du résultat
echo "[✔] Configuration terminée"
ip addr show br0
ip route