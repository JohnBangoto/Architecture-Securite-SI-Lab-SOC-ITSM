# 🛡️ Architecture & Sécurité d'un SI — Lab SOC/ITSM

> Déploiement d'une infrastructure de gestion centralisée avec supervision (Zabbix), sécurité (Wazuh), ticketing (GLPI) et gestion d'inventaire automatisés en environnement lab.

---

## 📐 Architecture

```
                          [ INTERNET ]
                               |
                          [ pfSense ]
                         Firewall/Router
                               |
              ┌────────────────┼────────────────┐
              |                |                |
        [ DC25 ]        [ Clients ]      [ ITSM SERVER ]
    Contrôleur AD       Win10/11        Ubuntu 24.04 LTS
    172.16.10.10     172.16.10.x     IP Publique: 192.146.xx.xx
    DHCP / DNS          GPO Auto
```

**Flux réseau :**
- 🔴 Trafic LAN / AD / DNS / DHCP
- 🟢 Supervision & métriques (Zabbix) — ports 10050/10051
- 🔵 Collecte logs & alertes SIEM (Wazuh) — ports 1514/1515
- ⬛ ITSM / CMDB / Ticketing (GLPI) — port 80/443

> 📄 Schéma complet : [`architecture/architecture-segmentation.drawio`](architecture/architecture-soc-segmentation.png)
---

## 📁 Structure du dépôt

```
Architecture-Securite-SI-Lab-SOC-ITSM/
├── architecture/
│   └── architecture-segmentation.drawio
├── config/
│   ├── GLPI/
│   │   ├── GLPI_AGENT.md
│   │   └── GLPI_SERVER.md
│   ├── pfsense/
│   │   ├── dhcp-relay.md
│   │   ├── firewall-rules.md
│   │   ├── interfaces.md
│   │   └── README.md
│   ├── VPS/
│   │   └── VPS.md
│   ├── wazuh/
│   │   ├── wazuh_agent.md
│   │   └── wazuh_server.md
│   ├── windows_server_AD/
│   │   ├── DHCP.md
│   │   ├── DNS.md
│   │   ├── limitations de stockage-users.md
│   │   ├── Pre-requis Exchange.md
│   │   ├── print_server.md
│   │   ├── securisation AD.md
│   │   └── Services-AD.md
│   └── zabbix/
│       ├── zabbix_agent
│       └── zabbix_server.md
├── docs/
├── scripts/
│   ├── GLPI_INSTALL_11.txt
│   ├── ZabbixInstallationLinux.bash
│   └── install_agents.ps1
└── README.md
```

---

## ✅ Services déployés

| Service | Rôle | Statut | Documentation |
|---------|------|--------|---------------|
| **pfSense** | Firewall / NAT / DHCP Relay | ✅ Opérationnel | [`config/pfsense/`](config/pfsense/) |
| **DC25 (AD)** | AD DS / DNS / DHCP / GPO | ✅ Opérationnel | [`config/windows_server_AD/`](config/windows_server_AD/) |
| **Zabbix 7.0** | Supervision & monitoring | ✅ Opérationnel | [`config/zabbix/`](config/zabbix/) |
| **Wazuh 4.9** | SIEM / EDR / Alertes sécurité | ✅ Opérationnel | [`config/wazuh/`](config/wazuh/) |
| **GLPI 11** | ITSM / Ticketing / CMDB | ✅ Opérationnel | [`config/GLPI/`](config/GLPI/) |
| **VPS** | Hébergement ITSM Server | ✅ Opérationnel | [`config/VPS/`](config/VPS/) |

---

## 🔄 Déploiement automatique via GPO

Les agents sont déployés automatiquement sur tous les postes clients via GPO Active Directory.

**Script :** [`scripts/install_agents.ps1`](scripts/install_agents.ps1)

```
GPO : Computer Configuration → Windows Settings → Scripts → Startup → PowerShell Scripts
Partage : \\DC25\GAgent$\
Agents  : GLPI Agent 1.15 + Wazuh 4.9.2 + Zabbix Agent 2 7.4.9
```

---

## 🔗 Intégrations configurées

### ✅ Zabbix → GLPI (Tickets automatiques)
- Webhook GLPi configuré dans Zabbix (Media Type)
- Création automatique de **tickets** GLPI à chaque alerte Zabbix
- Résolution automatique du ticket quand l'alerte se résout
- Lien direct vers l'événement Zabbix depuis le ticket GLPI

### ✅ Wazuh → GLPI (Tickets sécurité automatiques)
- Intégration via script Python sur le manager Wazuh
- Création automatique de tickets GLPI sur alertes de sécurité
- Corrélation incidents sécurité ↔ ticketing ITSM

### ✅ GLPI ↔ Inventaire automatique
- GLPI Agent remonte l'inventaire complet de chaque poste
- Synchronisation automatique via GPO au démarrage

---

## 🚧 Roadmap

### 🔐 VPN & Durcissement VPS
- [ ] **WireGuard** sur pfSense — accès distant sécurisé au réseau local
- [ ] Durcissement VPS :
  - [ ] Désactivation SSH root / authentification par clé uniquement
  - [ ] Fail2Ban — protection brute-force
  - [ ] UFW — restriction ports exposés
  - [ ] Unattended-upgrades — mises à jour automatiques de sécurité

### 🔴 Simulation d'attaques
- [ ] Machine **Kali Linux** intégrée au lab
- [ ] Attaques à simuler pour valider les alertes :
  - [ ] Brute-force SSH/RDP → alerte Wazuh (règle 5710)
  - [ ] Scan Nmap → alerte Wazuh + Zabbix
  - [ ] Élévation de privilèges → alerte Wazuh
  - [ ] Test EICAR (malware simulé) → alerte Wazuh
  - [ ] File Integrity Monitoring (FIM) → alerte Wazuh
  - [ ] DoS basique → alerte Zabbix CPU/RAM

### 🔗 Intégrations à venir
- [ ] **Grafana** — dashboards avancés connectés à Zabbix
- [ ] **GLPI Dashboard** — centralisation des metrics ITSM

### 🔍 Audit de l'infrastructure
- [ ] **Lynis** — audit durcissement Linux VPS
- [ ] **BloodHound** — audit permissions Active Directory
- [ ] **CIS Benchmark** — conformité postes Windows
- [ ] Audit règles pfSense (gestion des accès)

---

## 🔐 Règles pfSense (résumé)

```
LAN → ITSM SERVER : TCP 80, 1514/1515, 10050/10051
LAN → DC25        : UDP 53, TCP 88/389/445
WAN entrant       : Bloqué (par défaut)
LAN sortant       : NAT Masquerade
```
[text]
> 📄 Détail complet : [`config/pfsense/firewall-rules.md`](config/pfsense/firewall-rules.md)

---

## 🚀 Installation rapide

```bash
# GLPI 11
cat scripts/GLPI_INSTALL_11.txt

# Zabbix sur Linux
bash scripts/ZabbixInstallationLinux.bash

# Agents Windows (via GPO)
# Déposer dans \\DC25\GAgent$\ puis configurer la GPO Startup Script
```

---

## 📝 Licence

Projet réalisé à des fins éducatives dans un environnement lab isolé.
