# 🛡️ Politique de Filtrage et Durcissement (Firewall Rules)

L'infrastructure réseau repose sur une politique de **Default Deny**. Par défaut, tout trafic inter-zone est bloqué par le pare-feu pfSense. Seuls les flux critiques nécessaires à la supervision (SOC), aux services d'annuaire (AD) et au diagnostic réseau sont explicitement autorisés.

## ⚖️ Philosophie de Sécurité
Nous appliquons le principe du **moindre privilège** :
* **Isolation stricte** : Les segments `DATA_ZONE` et `SOC_ZONE` ne communiquent que via des ports spécifiques.
* **Filtrage État (Stateful)** : Le pare-feu autorise automatiquement le trafic retour pour les connexions établies.
* **Priorisation du Diagnostic** : Les règles ICMP (Ping) sont autorisées et journalisées sur chaque interface pour faciliter la maintenance et détecter toute tentative de reconnaissance (network scanning).

---

## 📋 Matrice des Flux : DATA_ZONE (Sortant)
*Contrôle des communications depuis le parc Windows/Clients vers le SOC.*

| Action | Protocole | Source | Port | Destination | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PASS** | TCP | `DATA_ZONE subnets` | 10051 | `172.16.20.100` | **Zabbix Trapper** : Envoi des métriques vers le SOC. |
| **PASS** | ICMP | `DATA_ZONE subnets` | * | `*` | **Ping** : Diagnostic réseau autorisé. |
| **PASS** | TCP | `DATA_ZONE subnets` | 1514-1515 | `172.16.20.100` | **Wazuh Agents** : Logs et Enrôlement. |

> **Note de durcissement** : Les règles "Default allow" d'usine ont été désactivées (grisées) pour forcer le passage par ces règles explicites.
![Règles DATA_ZONE](../../docs/assets/pfsense/RData_zone.png)

---

## 📋 Matrice des Flux : SOC_ZONE (Sortant)
*Contrôle des communications depuis les serveurs de supervision vers l'infrastructure et l'extérieur.*

| Action | Protocole | Source | Port | Destination | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PASS** | TCP/UDP | `SOC_ZONE subnets` | `AD_PORTS` | `172.16.10.10` | **Services AD** : Kerberos, LDAP, SMB via Alias. |
| **PASS** | ICMP | `SOC_ZONE subnets` | * | `*` | **Ping** : Diagnostic réseau autorisé. |
| **PASS** | TCP/UDP | `SOC_ZONE subnets` | 53 (DNS) | `172.16.10.10` | **DNS** : Résolution via le DC25. |
| **PASS** | TCP | `SOC_ZONE subnets` | 443 | Any | **Updates** : Mises à jour des signatures (WAN). |

> ![Règles SOC_ZONE](../../docs/assets/pfsense/RSOC_ZONE.png)

---

## ⚙️ Implémentation technique

### 1. Optimisation via les Alias
Un alias nommé **`AD_PORTS`** a été configuré pour regrouper les ports essentiels de l'Active Directory, assurant une meilleure lisibilité de la matrice de flux :
* **Ports inclus** : 88 (Kerberos), 389 (LDAP), 445 (SMB).
![ADPORTS](../../docs/assets/pfsense/ADPORTS.png)

### 2. Sécurité Périmétrale (Interface WAN)
L'interface WAN est configurée pour rejeter systématiquement le trafic provenant d'adresses non routables sur l'Internet public afin de prévenir l'IP Spoofing.

* **Block RFC1918** : Bloque les plages privées (10/8, 172.16/12, 192.168/16).
* **Block Bogon Networks** : Bloque les réseaux non attribués par l'IANA.

![Configuration du blocage WAN](../../docs/assets/pfsense/block.png)
> *Note : Dans ce lab, ces options sont décochées car le WAN du pfSense est lui-même sur un segment privé de l'hyperviseur.*

---

* **Journalisation (Logging)** : L'option "Log" est activée sur chaque règle métier. Cette visibilité est essentielle pour alimenter le SIEM (Wazuh) et permettre la détection d'anomalies réseau.
* **Anti-Lockout** : Une règle spécifique protège l'accès à l'interface d'administration (80/443) pour éviter toute perte de contrôle du pare-feu depuis le segment d'administration.

