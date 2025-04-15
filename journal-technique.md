# 📘 Journal de bord technique – Projet Réseaux Avancés SDN (Scénario 1)

---

## 🗓️ Initialisation
- Création du `Vagrantfile` avec les VMs suivantes : `ryu`, `router1`, `router2`, `client`.
- Ajout des IP fixes via réseau privé (`192.168.100.0/24`).
- Dossier structuré : `scripts/`, `configs/`, `ryu-apps/`.

---

## 🛠️ Déploiement des composants de base
- Installation et configuration de FRRouting (`frr`) sur les routeurs.
- Activation du daemon OSPF (`ospfd=yes` dans `/etc/frr/daemons`).
- Création des fichiers `frr.conf` pour `router1` et `router2`.

---

## 🧠 Intégration SDN
- Déploiement d'Open vSwitch (`ovs-vsctl`) sur `ryu`.
- Bridge `br0` connecté à `enp0s8`, relié au contrôleur Ryu.
- Script `http_redirect.py` opérationnel avec `ryu-manager`.

---

## 📊 Mise en place du monitoring
- Installation de Prometheus + Grafana sur `ryu`.
- Node Exporter installé sur toutes les VMs.
- Ajout du scrape config dans `prometheus.yml`.

---

## 🔎 Intégration de frr_exporter
- Tests avec versions `1.4.0`, `1.3.3` → incompatible avec `--frr.vtysh`.
- Adoption de `frr_exporter v1.0.0` avec support `--frr.vtysh`.
- Création et déploiement du service `frr_exporter.service` (port 9122).
- Ajout du user `frr` au groupe `frrvty`.

---

## 🧪 Tests Prometheus / curl
- Vérification des métriques sur `http://localhost:9122/metrics`.
- Exporters UP sur `router1` et `router2`.

---

## 📈 Dashboards Grafana
- Création et import du dashboard `FRR OSPF Monitoring`.
- Panels `OSPF Neighbors`, `Adjacencies`, `Routes`, `Time Series`.

---

## 📝 Génération des rapports de test
- Script `generate-report.sh` créé dans `scripts/`.
- Création d’un script global `run-all-reports.sh`.
- Tests générés pour chaque VM dans `tests/`.
- Ajout de `/tests/` au `.gitignore`.

---

## ❌ Problème détecté :
- OSPF "non actif" malgré services UP.

## ✅ Résolution :
- Mauvais nom d’interface dans `frr.conf` (`eth1` au lieu de `enp0s8`).
- Correction manuelle des fichiers sur `router1` et `router2`.
- Redémarrage de `frr`.

---

## ✅ 15/04/2025 – Validation finale OSPF
- `router1` voit `router2` en `Full/Backup`.
- `show ip ospf neighbor` OK des deux côtés.
- OSPF stable, métriques visibles et dashboards fonctionnels.

---

## 🔜 Prochaines étapes
- Génération du schéma réseau
- Rapport de soutenance
- Simulation de panne OSPF + observation Grafana