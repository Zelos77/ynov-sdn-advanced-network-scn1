# Projet Réseaux Avancés Cloud & SDN – Infrastructure FRR + Ryu + Monitoring

## 🎯 Objectif du projet

Concevoir, déployer et superviser une infrastructure réseau avancée dans un environnement cloud privé simulé avec :

- Routage dynamique via **FRRouting** (OSPF)
- Contrôle réseau programmable avec **Open vSwitch** + **Ryu Controller**
- Supervision avancée via **Prometheus** et **Grafana**
- Scripts d’automatisation (Bash) pour chaque rôle réseau

---

## 🖥️ Infrastructure VM

| VM           | Rôle                        | IP                  |
|--------------|-----------------------------|---------------------|
| ryu          | Contrôleur SDN + Monitoring | `192.168.100.10`    |
| router1      | Routeur OSPF + Exporter     | `192.168.100.21`    |
| router2      | Routeur OSPF + Exporter     | `192.168.100.22`    |
| client       | Client Linux + tests        | `192.168.100.30`    |

---

## Composants principaux

### FRRouting (OSPF)
- Daemon activé : `ospfd`
- Config via `/etc/frr/frr.conf`
- Routage dynamique entre `router1` et `router2`
- Routes injectées avec priorité (DR/BDR)

### Ryu Controller
- Contrôleur OpenFlow
- Script `http_redirect.py` :
  - Redirige le trafic HTTP
  - Collecte des flux
  - Envoie des règles OpenFlow aux bridges OVS

### Open vSwitch
- Bridge `br0` connecté à l’interface réseau
- Contrôleur : `tcp:192.168.100.10:6633`
- Règles injectées par Ryu via `ovs-ofctl`

---

## Monitoring avec Prometheus & Grafana

| Composant     | Port  | Fonction                                  |
|---------------|-------|-------------------------------------------|
| Prometheus    | 9090  | Collecte des métriques                    |
| Grafana       | 3000  | Visualisation des dashboards              |
| Node Exporter | 9100  | CPU, RAM, réseau (toutes les VMs)         |
| frr_exporter  | 9122  | Métriques OSPF extraites via vtysh        |
| Telegraf      | 9273  | Métriques système supplémentaires (client)|

### Prometheus scrape config :
```yaml
scrape_configs:
  - job_name: 'frr'
    static_configs:
      - targets:
          - 192.168.100.21:9122
          - 192.168.100.22:9122

  - job_name: 'nodes'
    static_configs:
      - targets:
          - 192.168.100.10:9100
          - 192.168.100.21:9100
          - 192.168.100.22:9100
          - 192.168.100.30:9100
```

---

## Scripts utilisés

### `frr-setup.sh`
- Installe FRR
- Configure OSPF
- Télécharge `frr_exporter` (v1.0.0)
- Crée le service systemd
- Expose les métriques sur le port 9122

### `ryu-setup.sh`
- Installe OVS, Prometheus, Grafana, Ryu
- Configure le bridge et le contrôleur OVS
- Démarre le script `http_redirect.py`

### `client-setup.sh`
- Installe les outils de test (ping, iperf, curl)
- Déploie un test script réseau
- Configure Telegraf pour Prometheus

### `common.sh`
- Tâches système : upgrade, swapoff, exporteurs, logs, sysctl, sudo

---

## Tests à réaliser

- `ping` entre client → routeurs
- `vtysh -c "show ip ospf neighbor"`
- `curl http://localhost:9122/metrics`
- `http://192.168.100.10:9090/targets` (Prometheus)
- `http://192.168.100.10:3000` (Grafana, admin/admin)

---

## 📈 Dashboards Grafana recommandés

- Dashboard a importer dans grafana depuis le dossier dashboard

---

## 🚀 Déploiement rapide

```bash
vagrant up
vagrant provision router1
vagrant provision router2
vagrant provision ryu
```

---

## 📦 Bonus

- Test de failover OSPF : désactive temporairement `router2`
- Capture réseau avec `tcpdump`
- Intégration future : VPN, BGP, overlay VXLAN, Istio

---

## 🛡️ Sécurité & extensions

- ACLs OpenFlow possibles dans Ryu
- TLS Prometheus + auth Grafana (via reverse proxy)
- Supervision auto avec alertes Grafana

---

## 🧠 À retenir

- `frr_exporter` doit être lancé avec :  
```bash
--frr.vtysh --frr.vtysh.path="/usr/bin/vtysh"
```
- Le user `frr` doit appartenir au groupe `frrvty`

---

## 📂 Arborescence du projet (extrait)

```
projet-sdn/
├── Vagrantfile
├── scripts/
│   ├── common.sh
│   ├── frr-setup.sh
│   ├── ryu-setup.sh
│   ├── client-setup.sh
├── configs/
│   ├── router1-frr.conf
│   ├── router2-frr.conf
├── ryu-apps/
│   └── http_redirect.py
```

---

## 📜 Licence

zelos engineering - Projet pédagogique dans le cadre du module Réseaux Avancés Cloud & SDN – Ynov 2025