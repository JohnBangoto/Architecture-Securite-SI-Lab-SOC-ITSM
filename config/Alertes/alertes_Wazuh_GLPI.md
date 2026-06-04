# 🚨 Intégration Wazuh → GLPI — Alertes de sécurité en Tickets automatiques

> **Environnement :** Wazuh Manager (`soc-server`) · GLPI `194.146.xx.xx` · Script Python `custom-glpi.py` · API REST GLPI Legacy

---

## Prérequis

Avant de configurer cette intégration, s'assurer que :
- L'**API REST GLPI** et l'**API Legacy** sont activées (`Configuration > Générale > API`)
- Un **client API** avec l'IP du `soc-server` est créé dans GLPI
- Le **user_token** et l'**app_token** GLPI sont disponibles
- Le service **Wazuh Manager** est opérationnel sur `soc-server`

---

## 1. Création de l'utilisateur GLPI dédié

Créer un utilisateur **dédié à Wazuh** afin de distinguer les tickets Wazuh des tickets des autres intégrations (ex: Zabbix).

> ⚠️ Ne pas utiliser un compte admin personnel ni un compte partagé avec une autre intégration — chaque intégration doit avoir son propre utilisateur pour une meilleure traçabilité.

**Chemin GLPI :** `Administration → Utilisateurs → +`

| Champ | Valeur |
|-------|--------|
| Identifiant | `wazuh-api` |
| Profil | Super-Admin |
| Entité | Entité racine |
| Activé | Oui |

**Récupérer les tokens :**

```
Cliquer sur wazuh-api
      ↓
Onglet "Accès distant à l'API"
      ↓
Regénérer le token si nécessaire
```

| Token | Portée |
|-------|--------|
| **User-Token** | Unique par utilisateur |
| **App-Token** | `Configuration → Générale → API` — commun à toute l'application |

**Tester la connexion API :**

```bash
curl -X GET "http://194.146.xx.xx/apirest.php/initSession" \
     -H "Authorization: user_token VOTRE_USER_TOKEN" \
     -H "App-Token: VOTRE_APP_TOKEN"
```

Réponse attendue :
```json
{"session_token":"xxxxxxxxxxxxxxxxxxxx"}
```

**Tester la création d'un ticket :**

```bash
curl -X POST "http://194.146.xx.xx/apirest.php/Ticket" \
     -H "Content-Type: application/json" \
     -H "Session-Token: VOTRE_SESSION_TOKEN" \
     -H "App-Token: VOTRE_APP_TOKEN" \
     -d '{
       "input": {
         "name": "Test Wazuh - Ticket automatique",
         "content": "Ceci est un ticket de test généré par Wazuh",
         "priority": 3,
         "type": 1
       }
     }'
```

Réponse attendue :
```json
{"id": 148, "message": "Élément ajouté : Test Wazuh - Ticket automatique"}
```

---

## 2. Création du script d'intégration custom-glpi.py

**Serveur :** `root@soc-server`
**Chemin système :** `/var/ossec/integrations/custom-glpi.py`

> 💡 Le script est versionné dans le dossier 'script' du projet. Le fichier déployé sur le serveur est une copie de `src/integrations/custom-glpi.py`.

Le script Python est créé directement sur le serveur Wazuh via un heredoc. Il assure la réception des alertes Wazuh et leur transmission à l'API GLPI sous forme de tickets.

**Commande de création :**

```bash
cat > /var/ossec/integrations/custom-glpi.py << 'EOF'
#!/usr/bin/env python3
import sys
import json
import requests
import urllib3
...
EOF
```

**Structure du script :**

```python
#!/usr/bin/env python3
import sys
import json
import requests
import urllib3

urllib3.disable_warnings()

GLPI_URL    = "http://194.146.xx.xx"
USER_TOKEN  = "ynwq1W5uYm7G2KL9d1XEgcloVHnDrn3AYwp9........."
APP_TOKEN   = "FSbET7LCH26sM5HsuZYXM3C2djZyDi5t.........."
```

**Mapping des niveaux de sévérité Wazuh → priorité GLPI :**

| Niveau Wazuh | Description | Priorité GLPI | Label |
|:---:|---|:---:|---|
| ≥ 13 | Critique | 6 | Très haute |
| 10 – 12 | Élevé | 5 | Haute |
| 7 – 9 | Moyen-haut | 4 | Moyenne haute |
| < 7 | Moyen | 3 | Moyenne |

```python
def get_priority(level):
    level = int(level)
    if level >= 13:
        return 6  # Très haute
    elif level >= 10:
        return 5  # Haute
    elif level >= 7:
        return 4  # Moyenne haute
    else:
        return 3  # Moyenne

def get_session_token():
    headers = {
        'Authorization': f'user_token {USER_TOKEN}',
        'App-Token': APP_TOKEN,
        ...
    }
```

> 💡 La fonction `get_priority()` traduit les niveaux de sévérité Wazuh (1–15) en niveaux de priorité GLPI (3–6), permettant une priorisation cohérente des tickets de sécurité.

![Création script custom-glpi.py](../../docs/assets/GLPI-WAZUH/1.png)

---

## 3. Configuration de l'intégration dans ossec.conf

**Chemin :** `/var/ossec/etc/ossec.conf`
**Éditeur :** `nano`

Le bloc `<integration>` est ajouté à la fin du fichier de configuration principal de Wazuh, juste avant la balise fermante `</ossec_config>`.

**Bloc de configuration ajouté :**

```xml
<integration>
    <name>custom-glpi</name>
    <hook_url>http://194.146.xx.xx/apirest.php</hook_url>
    <level>7</level>
    <alert_format>json</alert_format>
</integration>
```

**Explication des paramètres :**

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `<name>` | `custom-glpi` | Nom du script d'intégration (correspond au fichier `custom-glpi.py`) |
| `<hook_url>` | `http://194.146.xx.xx/apirest.php` | URL de l'API REST GLPI |
| `<level>` | `7` | Niveau minimum d'alerte Wazuh déclenchant l'envoi vers GLPI |
| `<alert_format>` | `json` | Format des données transmises au script |

> ⚠️ Seules les alertes de **niveau ≥ 7** sont transmises à GLPI. Ajuster cette valeur selon le volume d'alertes souhaité. Un niveau trop bas (ex: 1) générerait un volume de tickets très important.

> 💡 Le champ `<localfile>` visible en haut de la capture (`/var/log/dpkg.log`) est une configuration existante — le bloc `<integration>` est ajouté juste en dessous avant `</ossec_config>`.

![Configuration ossec.conf](../../docs/assets/GLPI-WAZUH/2.png)

---

## 4. Permissions et dépendances du script

**Serveur :** `root@soc-server`

Après création du script, les permissions correctes sont appliquées et la dépendance Python `requests` est installée.

**Commandes exécutées :**

```bash
# Rendre le script exécutable (lecture/exécution pour root et wazuh)
chmod 750 /var/ossec/integrations/custom-glpi.py

# Assigner la propriété à root:wazuh (requis par Wazuh)
chown root:wazuh /var/ossec/integrations/custom-glpi.py

# Installer la librairie requests pour Python3
pip3 install requests --break-system-packages
```

**Résultat :**

```
no such option: --break-system-packages
```

> ⚠️ Le flag `--break-system-packages` n'est pas supporté sur cette version de pip3. Utiliser à la place :
> ```bash
> pip3 install requests
> # ou, si pip3 n'est pas disponible :
> apt install python3-requests
> ```

**Récapitulatif des permissions :**

| Fichier | Permissions | Propriétaire |
|---------|-------------|--------------|
| `/var/ossec/integrations/custom-glpi.py` | `750` (rwxr-x---) | `root:wazuh` |

> 💡 Les permissions `750` et le propriétaire `root:wazuh` sont obligatoires — Wazuh exécute les scripts d'intégration sous l'utilisateur `wazuh` et refuse les scripts avec des permissions trop ouvertes.

**Redémarrage du service après configuration :**

```bash
systemctl restart wazuh-manager
```

![Permissions et dépendances](../../docs/assets/GLPI-WAZUH/3.png)

---

## 5. Liste des tickets Wazuh générés dans GLPI

**Chemin GLPI :** `Assistance > Tickets`

Une fois l'intégration opérationnelle, les alertes Wazuh de niveau ≥ 7 sont automatiquement créées comme tickets dans GLPI. Le préfixe `[Wazuh]` dans le titre permet de les identifier immédiatement.

**Vue d'ensemble des tickets générés :**

| Statut | Nombre |
|--------|--------|
| Total Tickets | **762** |
| Tickets entrants | 715 |
| Tickets en attente | 0 |
| Tickets assignés | 0 |
| Tickets planifiés | 47 |
| Tickets résolus | — |

**Exemples de tickets Wazuh récents :**

| ID | Titre | Statut | Date | Priorité |
|----|-------|--------|------|----------|
| 762 | **[Wazuh] syslog: User missed the password more than one time** | 🟢 Nouveau | 2026-04-14 06:27 | **Haute** |
| 761 | [Wazuh] sshd: authentication failed. | 🟢 Nouveau | 2026-04-14 06:27 | Moyenne |
| 760 | [Wazuh] sshd: authentication failed. | 🟢 Nouveau | 2026-04-14 06:26 | Moyenne |
| 759 | [Wazuh] sshd: authentication failed. | 🟢 Nouveau | 2026-04-14 06:26 | Moyenne |
| 758 | [Wazuh] sshd: authentication failed. | 🟢 Nouveau | 2026-04-14 06:26 | Moyenne |
| 757 | [Wazuh] sshd: authentication failed. | 🟢 Nouveau | 2026-04-14 06:26 | Moyenne |

> Les multiples tickets `sshd: authentication failed` consécutifs indiquent une **tentative de brute-force SSH** sur le serveur `soc-server` depuis l'IP `45.148.10.147`, générée automatiquement par les règles Wazuh. Le ticket #762 à priorité **Haute** signale une escalade : l'utilisateur a raté le mot de passe plusieurs fois de suite (règle 2502).

![Liste tickets Wazuh dans GLPI](../../docs/assets/GLPI-WAZUH/4.png)

---

## 6. Détail d'un ticket Wazuh dans GLPI

**Chemin GLPI :** `Assistance > Tickets > Ticket #762`

Chaque ticket Wazuh contient les données complètes de l'alerte de sécurité dans sa description, permettant une investigation directe depuis GLPI.

**Ticket #762 — Contenu :**

```
[Wazuh] syslog: User missed the password more than one time

Agent     : soc-server (N/A)
Niveau    : 10
Règle     : 2502 — syslog: User missed the password more than one time
Groupes   : syslog, access_control, authentication_failed
Données   : { "srcip": "45.148.10.147", "dstuser": "root" }
Timestamp : 2026-04-14T06:27:03.218+0000
```

**Métadonnées du ticket :**

| Champ | Valeur |
|-------|--------|
| Type | **Incident** |
| Statut | 🟢 Nouveau |
| Date d'ouverture | 2026-04-14 |
| Catégorie | — |

**Analyse de l'alerte :**

| Champ | Valeur | Signification |
|-------|--------|---------------|
| Agent | `soc-server` | Machine source de l'alerte |
| Niveau | `10` | Sévérité élevée (→ priorité GLPI : 5 — Haute) |
| Règle | `2502` | Règle Wazuh : échecs de connexion répétés |
| Groupes | `syslog, access_control, authentication_failed` | Catégories de la règle |
| srcip | `45.148.10.147` | IP source de l'attaque |
| dstuser | `root` | Compte ciblé |
| Timestamp | `2026-04-14T06:27:03.218+0000` | Horodatage exact de l'événement |

> 🔴 Cette alerte indique une tentative d'accès SSH avec le compte **root** depuis l'IP externe `45.148.10.147`. Le niveau **10** (élevé) a correctement déclenché la création d'un ticket de priorité **Haute** dans GLPI, conformément au mapping de sévérité défini dans le script.

![Détail ticket Wazuh GLPI](../../docs/assets/GLPI-WAZUH/5.png)

---

