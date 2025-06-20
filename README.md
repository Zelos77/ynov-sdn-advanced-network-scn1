# Projet Réseaux Avancés Cloud & SDN – Infrastructure FRR + Ryu + Monitoring

## Objectif du projet

Concevoir, déployer et superviser une infrastructure réseau avancée dans un environnement cloud privé simulé avec :

- Routage dynamique via **FRRouting** (OSPF)
- Contrôle réseau programmable avec **Open vSwitch** + **Ryu Controller**
- Supervision avancée via **Prometheus** et **Grafana**
- Scripts d’automatisation (Bash) pour chaque rôle réseau

---

## Correspondance avec les objectifs pédagogiques

| Exigence pédagogique                        | Implémentation technique                                   |
|--------------------------------------------|------------------------------------------------------------|
| Routage dynamique (OSPF)                   | FRRouting sur router1 et router2 avec `ospfd`              |
| Contrôle SDN avec contrôleur programmable  | Ryu Controller (script `http_redirect.py`)                |
| Bridge programmable                        | Open vSwitch (`br0`) sur chaque routeur                   |
| Supervision centralisée                    | Prometheus + Grafana + `node_exporter` + `frr_exporter`   |
| Métriques OSPF exploitées                  | Export via `frr_exporter` + Prometheus scrape             |
| Automatisation des rôles                   | Scripts Bash (`frr-setup.sh`, `ryu-setup.sh`, etc.)       |
| Tests réseau                               | Ping, curl, HTTP redirect, observation des métriques      |
| Documentation                              | README complet + journal technique + diagramme réseau     |

---

## Infrastructure VM

| VM           | Rôle                        | IP                  |
|--------------|-----------------------------|---------------------|
| ryu          | Contrôleur SDN + Monitoring | `192.168.100.10`    |
| router1      | Routeur OSPF + Exporter     | `192.168.100.21`    |
| router2      | Routeur OSPF + Exporter     | `192.168.100.22`    |
| client       | Client Linux + tests        | `192.168.100.30`    |

---

## Déploiement rapide

```bash
S'assurer que le end of line sequence est en "LF" plutot que CRLF

Lancer la commande : vagrant up

- vérifier les targets Prometheus http://192.168.100.10:9090/targets
- Importer un dashboard dans grafana http://192.168.100.10:3000 (login: admin/admin)
```

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

| Composant     | Port  | Fonction                                                 |
|---------------|-------|----------------------------------------------------------|
| Prometheus    | 9090  | Collecte des métriques                                   |
| Grafana       | 3000  | Visualisation des dashboards                             |
| Node Exporter | 9100  | CPU, RAM, réseau (toutes les VMs)                        |
| frr_exporter  | 9122  | Métriques OSPF extraites via vtysh    (pas config)       | 
| Telegraf      | 9273  | Métriques système supplémentaires (client) (pas config)  |

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

### `ovs-setup.sh`
- Installe Open vSwitch
- Crée le bridge br0, attache les interfaces
- Configure le contrôleur OVS vers la VM ryu

---

## Tests à réaliser

- `ping` entre client → routeurs
- `vtysh -c "show ip ospf neighbor"`
- `curl http://localhost:9122/metrics`
- `http://192.168.100.10:9090/targets` (Prometheus)
- `http://192.168.100.10:3000` (Grafana, admin/admin)

---

## Dashboards Grafana recommandés

- Dashboard a importer dans grafana depuis le dossier dashboard

---

## À retenir

- `frr_exporter` doit être lancé avec :  
```bash
--frr.vtysh --frr.vtysh.path="/usr/bin/vtysh"
```
- Le user `frr` doit appartenir au groupe `frrvty`

---

## 📜 Licence

zelos engineering - Projet pédagogique dans le cadre du module Réseaux Avancés Cloud & SDN – Ynov M1 infra 2025
