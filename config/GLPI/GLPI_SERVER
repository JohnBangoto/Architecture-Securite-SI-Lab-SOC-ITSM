# 🖥️ Installation et Configuration de GLPI — Serveur SOC

> **Environnement :** Debian/Ubuntu — Serveur `soc-server` — GLPI version **11.0.5**  
> **Objectif :** Déployer GLPI via un script d'installation automatisé, puis sécuriser l'instance en créant un compte administrateur dédié et en désactivant les comptes par défaut

---

## 1. Connexion SSH et création du script d'installation

La première étape consiste à se connecter au serveur `soc-server` en SSH et à créer le script d'installation de GLPI.

```
# Création du script d'installation
root@soc-server:~# nano install.sh
```

> La connexion est effectuée en tant que **root** depuis l'adresse `41.83.125.48`. L'éditeur `nano` est utilisé pour créer le script `install.sh` qui automatisera l'installation complète de GLPI et de ses dépendances.

![Connexion SSH et création install.sh](../../docs/assets/GLPI/glpi_server/1.png)

---

## 2. Contenu du script install.sh — Variables de configuration

Le script `install.sh` est un installateur automatisé pour **GLPI 11 sur Debian/Ubuntu**. Il est ouvert dans **GNU nano 6.2**.

![Script install.sh — Variables de configuration](../../docs/assets/GLPI/glpi_server/2.png)

---

## 3. Exécution du script — Étape 1/10

Après sauvegarde du script, le rendre exécutable et le lancer :

```bash
chmod +x install.sh
./install.sh
```
![Exécution install.sh — Étape 1/10](../../docs/assets/GLPI/glpi_server/3.png)

---

## 4. Accès à l'interface web GLPI

Une fois l'installation terminée, GLPI est accessible via le navigateur web.

**URL d'accès :** `http://<IP_SERVEUR>/glpi`

La page de **login** s'affiche avec :

| Champ | Description |
|-------|-------------|
| **Login** | Identifiant de l'utilisateur GLPI |
| **Password** | Mot de passe |
| **Login source** | `GLPI internal database` *(par défaut)* |

> Les identifiants par défaut de GLPI sont `glpi / glpi` pour l'administrateur. Il est impératif de changer ces mots de passe et de désactiver les comptes par défaut après la première connexion.

![Page de login GLPI](../../docs/assets/GLPI/glpi_server/4.png)

---

## 5. Dashboard GLPI — Vue d'ensemble

Après connexion en tant que **Super-Admin**, le **tableau de bord** affiche une vue synthétique du parc et de l'assistance par defaut.

![Dashboard GLPI — Super-Admin](../../docs/assets/GLPI/glpi_server/5.png)

---

## 6. Création d'un utilisateur administrateur — ROMANO

Pour sécuriser l'instance, créer un compte administrateur dédié en remplacement du compte `glpi` par défaut.

**Accès :** Administration → **Utilisateurs** → bouton `+`

| Champ | Valeur |
|-------|--------|
| **Identifiant** | `ROMANO` |
| **Nom de famille** | *(à compléter)* |
| **Prénom** | *(à compléter)* |
| **Fuseau horaire** | *(non activé — voir note)* |
| **Activé** | `Oui` |

> Le message concernant les fuseaux horaires indique qu'il faut exécuter la commande `php bin/console database:enable_timezones` pour les activer — fonctionnalité non critique pour le déploiement initial.

![Création utilisateur ROMANO](../../docs/assets/GLPI/glpi_server/6.png)

---

## 7. Attribution du profil Super-Admin à ROMANO

Dans la section **Habilitation** du formulaire utilisateur, configurer les droits d'accès :

| Paramètre | Valeur |
|-----------|--------|
| **Récursif** | Non |
| **Profil** | `Super-Admin` |
| **Entité** | `Entité racine` |

> Le profil **Super-Admin** donne un accès total à toutes les fonctionnalités de GLPI. L'attribution à l'**Entité racine** sans récursivité signifie que l'accès s'applique uniquement à l'entité principale. Sauvegarder pour créer le compte.

![Habilitation ROMANO — Super-Admin, Entité racine](../../docs/assets/GLPI/glpi_server/7.png)

---

## 8. Liste des utilisateurs GLPI

Après création de `ROMANO`, la liste **Administration → Utilisateurs** affiche les 6 comptes présents :

| Identifiant | Nom | Activé | Note |
|-------------|-----|--------|------|
| `glpi` | — | Oui | ⚠️ Compte admin par défaut |
| `post-only` | — | Oui | ⚠️ Compte de démonstration |
| `tech` | — | Oui | ⚠️ Compte de démonstration |
| `normal` | — | Oui | ⚠️ Compte de démonstration |
| `glpi-system` | Support | Oui | Compte système interne |
| **`ROMANO`** | — | **Oui** | ✅ Nouveau compte admin dédié |

> Les 4 comptes cochés (`glpi`, `post-only`, `tech`, `normal`) sont les **comptes de démonstration** créés par défaut à l'installation. Ils doivent être désactivés pour des raisons de sécurité — c'est l'objet de l'étape suivante.

![Liste des utilisateurs GLPI](../../docs/assets/GLPI/glpi_server/8.png)

---

## 9. Désactivation des comptes par défaut

Les comptes par défaut (`glpi`, `post-only`, `tech`, `normal`) sont sélectionnés en masse et désactivés via l'action groupée.

**Procédure :**
1. Cocher les 4 comptes par défaut dans la liste
2. Cliquer sur **Actions**
3. Configurer l'action :

| Paramètre | Valeur |
|-----------|--------|
| **Action** | `Modifier` |
| **Champ à mettre à jour** | `Caractéristiques - Activé` |
| **Nouvelle valeur** | `Non` |

4. Cliquer **Envoyer**

> ✅ Cette étape est **critique pour la sécurité** de l'instance GLPI. Les mots de passe des comptes par défaut sont publiquement connus (`glpi/glpi`, `tech/tech`, etc.). Les désactiver immédiatement après création du compte `ROMANO` empêche tout accès non autorisé.  
> Le compte `glpi-system` n'est pas désactivé car il est utilisé en interne par GLPI pour ses tâches automatisées (cron, notifications, etc.).

![Désactivation des comptes par défaut](../../docs/assets/GLPI/glpi_server/9.png)

---

