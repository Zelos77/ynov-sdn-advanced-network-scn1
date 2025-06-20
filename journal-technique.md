# 📘 Journal de bord technique – Projet Réseaux Avancés SDN (Scénario 1)

##  Initialisation

- Création du `Vagrantfile` avec les VMs suivantes : `ryu`, `router1`, `router2`, `client`.
- Attribution d’IP fixes via réseau privé (192.168.100.0/24).
- Arborescence projet structurée :
  - `scripts/` : automatisation
  - `configs/` : fichiers FRR
  - `ryu-apps/` : contrôleur Ryu

##  Déploiement des composants de base

- Installation et configuration de FRRouting (frr) sur les routeurs.
- Activation du daemon OSPF (via `/etc/frr/daemons` → `ospfd=yes`).
- Création des fichiers `frr.conf` adaptés pour `router1` et `router2`.

## Intégration SDN

- Installation et configuration d’Open vSwitch (OVS) sur la VM `ryu`.
- Création automatique du bridge `br0` relié à l’interface `enp0s8`.
- Script `scripts/ovs-setup.sh` :
  - Détecte dynamiquement l’interface réelle
  - Crée le bridge si nécessaire
  - Transfère automatiquement l’adresse IP et la route par défaut vers `br0`
- Contrôleur Ryu opérationnel (via `ryu-manager`) avec l’application `http_redirect.py`.

## Mise en place du monitoring

- Installation de Prometheus et Grafana sur la VM `ryu`.
- Installation de `node_exporter` sur toutes les VMs.
- Configuration du `prometheus.yml` avec `scrape_configs` adaptés.

## Intégration de frr_exporter

- Tests avec plusieurs versions : 1.4.0, 1.3.3 (incompatibles avec `--frr.vtysh`)
- Utilisation de la version 1.0.0 fonctionnelle avec `--frr.vtysh`.
- Déploiement du service `frr_exporter.service` (exposition sur le port 9122).
- Ajout de l’utilisateur `frr` au groupe `frrvty` pour l’accès à `vtysh`.

## 🧪 Tests Prometheus / curl

- Vérification des métriques OSPF :
  - http://localhost:9122/metrics
- Exporters UP sur `router1` et `router2`.

## Dashboards Grafana

- Création du dashboard FRR/OSPF Monitoring.
- Panels affichés :
  - OSPF Neighbors
  - Adjacencies
  - Routing Tables
  - Courbes de temps

## Génération des rapports de test

- Création du script `scripts/generate-report.sh`.
- Script global `run-all-reports.sh` pour lancer tous les tests.
- Fichiers de résultats dans le dossier `tests/`.
- Dossier `tests/` ajouté au `.gitignore`.

## Problème détecté

- OSPF "non actif" malgré services UP sur les deux routeurs.

## Résolution

- Mauvais nom d’interface dans `frr.conf` (`eth1` au lieu de `enp0s8`).
- Correction manuelle des interfaces.
- Redémarrage du service `frr`.

## 15/04/2025 – Validation finale OSPF

- `router1` voit `router2` en Full/Backup.
- Commande `show ip ospf neighbor` fonctionnelle des deux côtés.
- OSPF stable, métriques visibles, dashboard complet.

## 20/06/2025 – Automatisation OVS & Réseau SDN

- Script `ovs-setup.sh` finalisé :
  - Gestion propre du bridge OVS `br0`
  - Transfert dynamique de l’adresse IP
  - Résolution automatique de la route par défaut
- Le bridge est prêt pour recevoir les flux contrôlés depuis Ryu.
- Architecture SDN pleinement fonctionnelle avec base OSPF + SDN.
