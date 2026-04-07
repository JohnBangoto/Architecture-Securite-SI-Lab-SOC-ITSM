# 🖥️ Lab Documentation — Installation et Configuration de Zabbix 7.0

> **Environnement :** Ubuntu 22.04 / 24.04 — MariaDB — Apache2  
> **Version Zabbix :** 7.0.24  
> **Serveur :** `1194.146.**.**`

---

## 1. Script d'installation automatisé

Le déploiement de Zabbix 7.0 est réalisé via un script Bash non-interactif (`#!/bin/bash`) conçu pour fonctionner sur Ubuntu 22.04 et 24.04.

### Caractéristiques du script

- **Base de données :** MariaDB avec authentification `unix_socket` pour root (pas de prompt de mot de passe)
- **Utilisateur DB :** `zabbix` / Mot de passe fixé à `Password*` *(lab uniquement — à changer en production)*
- **Idempotent :** peut être relancé sans effets de bord
- **Détection automatique** de la version Ubuntu (22 ou 24) pour adapter l'URL du dépôt Zabbix

### Variables principales définies dans le script

| Variable | Valeur |
|---|---|
| `DB_NAME` | `zabbix` |
| `DB_USER` | `zabbix` |
| `DB_PASS` | `Password*` |
| `SECRETS_FILE` | `/root/.zabbix-db.cnf` |
| `ZBX_REPO_BASE` | `https://repo.zabbix.com/zabbix/7.0/ubuntu/...` |

![Vue du script Bash (variables, helpers, trap ERR)](../../docs/assets/zabbix/Zabbix_Server/1.png)

---

## 2. Résultat de l'exécution du script

À la fin de l'exécution, le script affiche un résumé complet de l'installation :

- **UFW** configuré pour autoriser le port HTTP (80) et le port Zabbix (10051)
- Les services `zabbix-server`, `zabbix-agent` et `apache2` sont activés et démarrés via `systemd`
- Un symlink systemd est créé pour le démarrage automatique de `zabbix-server`

### Informations de connexion affichées en fin de script

| Paramètre | Valeur |
|---|---|
| Frontend | `http://194.146.**.**/zabbix` |
| Login | `Admin / zabbix` |
| Base de données | `zabbix` (user: zabbix) |
| Mot de passe | Stocké dans `/root/.zabbix-db.cnf` |

> ⚠️ Le script avertit que le mot de passe `Password*` est non sécurisé pour un environnement de production.

![Sortie terminal montrant les services démarrés et le résumé final](../../docs/assets/zabbix/Zabbix_Server/2.png)

---

## 3. Accès à l'interface web — Page de bienvenue

Après l'installation, accéder à l'interface web via :

```
http://194.146.38.216/zabbix/setup.php
```

L'assistant de configuration Zabbix 7.0 s'ouvre. Il présente les étapes suivantes dans le menu latéral gauche :

1. Welcome
2. Check of pre-requisites
3. Configure DB connection
4. Settings
5. Pre-installation summary
6. Install

La langue par défaut sélectionnée est **English (en_US)**.

![Page de bienvenue de l'assistant de configuration Zabbix 7.0](../../docs/assets/zabbix/Zabbix_Server/3.png)

---

## 4. Configuration initiale — Paramètres du serveur

Dans l'étape **Settings** de l'assistant, les paramètres suivants ont été définis :

| Paramètre | Valeur configurée |
|---|---|
| Zabbix server name | `zabbix_server` |
| Default time zone | `System: (UTC+00:00) UTC` |
| Default theme | `Blue` |

![Page Settings de l'assistant avec les valeurs renseignées](../../docs/assets/zabbix/Zabbix_Server/4.png)

---

## 5. Tableau de bord global (Global view)

Après connexion avec les identifiants `Admin / zabbix`, le tableau de bord **Global view** est accessible. Il affiche :

### Informations système

| Paramètre | Valeur |
|---|---|
| Zabbix server is running | **Yes** — `localhost:10051` |
| Zabbix server version | `7.0.24` |
| Zabbix frontend version | `7.0.24` |
| Nombre d'hôtes (activés/désactivés) | 1 (1 / 0) |
| Nombre de templates | 354 |
| Nombre d'items (activés/désactivés/non supportés) | 128 (117 / 0 / 11) |

### Widgets visibles

- **Top hosts by CPU utilization** : le Zabbix server lui-même à 0.29% d'utilisation CPU
- **Zabbix server values per second** : ~1.73 valeurs/sec
- **Host availability** : 1 hôte disponible, 0 indisponible
- **Problems by severity** : aucun problème actif (0 dans toutes les catégories)
- **Geomap** : carte de localisation des hôtes

![Tableau de bord Global view après connexion](../../docs/assets/zabbix/Zabbix_Server/5.png)

---

## 6. Liste des hôtes surveillés

Depuis le menu **Data collection → Hosts**, on accède à la liste des hôtes configurés. À ce stade initial, un seul hôte est présent :

| Hôte | Interface | Templates | Statut | Disponibilité |
|---|---|---|---|---|
| Zabbix server | `127.0.0.1:10050` | Linux by Zabbix agent, Zabbix server health | Enabled | ZBX (vert) |

Le filtre de recherche permet de filtrer par groupes, templates, nom, DNS, IP, port, statut et tags.

![Page Hosts avec le Zabbix server comme seul hôte listé](../../docs/assets/zabbix/Zabbix_Server/6.png)

---

## 7. Sélection d'un template Windows

Pour ajouter un hôte Windows, on sélectionne un template depuis le groupe **Templates/Operating systems**. Le template choisi est :

> ✅ **Windows by Zabbix agent active**

Ce template est adapté à la supervision d'hôtes Windows via un agent Zabbix en mode actif (l'agent initie la connexion vers le serveur).

D'autres templates disponibles dans ce groupe : Linux by SNMP, Linux by Zabbix agent, macOS by Zabbix agent, Windows by SNMP, Windows by Zabbix agent, etc.

![Fenêtre de sélection de template avec "Windows by Zabbix agent active" coché](../../docs/assets/zabbix/Zabbix_Server/7.png)

---

## 8. Sélection du groupe d'hôtes

Le nouvel hôte Windows est rattaché au groupe d'hôtes **Virtual machines**, sélectionné depuis la liste des groupes disponibles :

- Applications
- Databases
- Discovered hosts
- Hypervisors
- Linux servers
- **Virtual machines** ✅
- Zabbix servers

![Fenêtre de sélection du groupe d'hôtes avec "Virtual machines" coché](../../docs/assets/zabbix/Zabbix_Server/8.png)

---

## 9. Vue d'ensemble des hôtes configurés

Après ajout des hôtes Windows et FreeBSD, la liste complète des hôtes supervisés comprend **4 hôtes** :

| Hôte | Interface | Tags | Statut | Items | Problèmes |
|---|---|---|---|---|---|
| Client-01 | `127.0.0.1:10050` | class: os / target: windows | Enabled | 110 | 1 (orange) |
| DC25 | `172.16.10.10:10050` | class: os / target: windows | Enabled | 135 | Problèmes |
| pfSense | `127.0.0.1:10050` | class: os / target: freebsd | Enabled | 51 | Problèmes |
| Zabbix server | `127.0.0.1:10050` | class: os / class: software / target: linux | Enabled | 146 | Problèmes |

![Vue complète des 4 hôtes dans Monitoring > Hosts](../../docs/assets/zabbix/Zabbix_Server/9.png)

---

## 10. Monitoring — Interface Hosts (vue filtre)

La même page Hosts est aussi accessible depuis l'interface minimaliste (icône latérale). Elle affiche les mêmes informations avec une présentation légèrement différente. À noter que **pfSense n'apparaît plus** dans cette vue, indiquant qu'il a pu être retiré ou filtré.

| Hôte | Interface | Tags | Latest data | Problèmes |
|---|---|---|---|---|
| Client-01 | `127.0.0.1:10050` | class: os / target: windows | 48 items | 1 |
| DC25 | `172.16.10.10:10050` | class: os / target: windows | 135 items | 2 |
| Zabbix server | `127.0.0.1:10050` | class: os / class: software / target: linux | 146 items | Problèmes |

![Interface Hosts en vue filtre (3 hôtes visibles)](../../docs/assets/zabbix/Zabbix_Server/10.png)

---

## 11. Alertes — Problème détecté sur Client-01

Dans **Monitoring → Problems**, une alerte de sévérité **Average** est détectée sur l'hôte **Client-01** :

| Champ | Détail |
|---|---|
| Heure | 12:40:02 AM |
| Sévérité | Average (orange) |
| Statut | PROBLEM |
| Hôte | Client-01 |
| Problème | `Windows: FS [(C:)]: Space is critically low (used > 90%, total 19.3GB)` |
| Durée | 16m 37s |
| Tags | class: os / component: storage / filesystem: C: |

Le disque C: de Client-01 est rempli à plus de 90% (18.58 GB utilisés sur 19.35 GB total), ce qui a déclenché l'alerte.

![Alerte disque plein sur Client-01 dans la vue Problems](../../docs/assets/zabbix/Zabbix_Server/11.png)

---

## 12. Alertes — Problèmes détectés sur DC25

Deux alertes de sévérité **Average** sont actives sur l'hôte **DC25** :

| Heure | Problème | Durée |
|---|---|---|
| 12:45:59 AM | `Windows: "InventorySvc" (Inventory and Compatibility Appraisal service) is not running (startup type automatic delayed)` | 11m 9s |
| 12:45:38 AM | `Windows: "AppXSvc" (AppX Deployment Service (AppXSVC)) is not running (startup type automatic)` | 11m 30s |

Ces alertes indiquent que deux services Windows configurés en démarrage automatique ne sont pas en cours d'exécution sur le contrôleur de domaine DC25.

![Alertes services Windows sur DC25 dans Monitoring > Problems](../../docs/assets/zabbix/Zabbix_Server/12.png)

---

## 13. Dashboard hôte — Système de fichiers (Client-01)

Depuis **Monitoring → Hosts → Client-01 → Dashboards**, l'onglet **Filesystems** affiche un graphique en camembert de l'utilisation du disque C: :

- **Capacité totale :** 19.35 GB (100%)
- **Espace utilisé :** 18.58 GB (**96.03%** — zone rouge)
- **Espace libre :** 785.93 MB (3.97% — zone verte)

Ce graphique confirme visuellement l'alerte déclenchée à l'étape précédente. Le disque est critique avec moins de 4% d'espace disponible.

![Graphique camembert Filesystems de Client-01 (96% utilisé)](../../docs/assets/zabbix/Zabbix_Server/13.png)

---

## 14. Dashboard hôte — Interfaces réseau (Client-01)

L'onglet **Network interfaces** du dashboard de Client-01 affiche le trafic réseau en temps réel sur l'interface **Intel(R) 82574L Gigabit Network Connection (Ethernet0)** :

- Plage affichée : de 12:00 AM à ~01:00 AM (dernière heure)
- Le trafic commence à apparaître vers 12:44 AM, atteignant ~1.5–2.0 Kbps
- Courbes : trafic entrant (vert) et sortant (rouge)

![Graphique trafic réseau Ethernet0 de Client-01](../../docs/assets/zabbix/Zabbix_Server/14.png)

---

## 15. Dashboard hôte — Performance système (Client-01)

L'onglet **System performance** affiche les métriques CPU de Client-01 :

- **Windows: CPU usage** : graphique sur 1 heure avec une ligne de seuil à 50% (pointillés orange). L'utilisation réelle reste très basse (proche de 0%)
- **CPU queue length** : file d'attente CPU très faible (< 0.2), indiquant que le système n'est pas sous charge

![Graphiques CPU usage et CPU queue length de Client-01](../../docs/assets/zabbix/Zabbix_Server/15.png)

---

## Résumé de l'architecture mise en place

```
┌─────────────────────────────────────────────────────┐
│                  Zabbix Server 7.0.24               │
│              Ubuntu — 194.146.**.**                │
│         (MariaDB + Apache2 + Zabbix Agent)          │
└──────────────┬──────────────────────────────────────┘
               │ Surveillance via Zabbix Agent (ZBX)
       ┌───────┼────────────────────┐
       ▼       ▼                    ▼
  ┌─────────┐ ┌──────────────────┐ ┌──────────┐
  │Client-01│ │      DC25        │ │ pfSense  │
  │Windows  │ │Windows Server    │ │ FreeBSD  │
  │(ZBX)    │ │172.16.10.10:10050│ │(ZBX)     │
  └─────────┘ └──────────────────┘ └──────────┘
```

