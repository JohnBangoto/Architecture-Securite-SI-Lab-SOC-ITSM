# 💾 Configuration des Quotas FSRM — Windows Server 2025

> **Environnement :** Windows Server 2025 — Domaine `lab.local` — Serveur `DC25.lab.local`  
> **Objectif :** Limiter l'espace disque des dossiers personnels des utilisateurs à **2 Go** via le **File Server Resource Manager (FSRM)**

---

## 1. Installation du rôle File Server Resource Manager

Le **File Server Resource Manager (FSRM)** est un sous-rôle de **File and Storage Services** qui permet de gérer les quotas, le filtrage de fichiers et les rapports de stockage.

**Accès :** Server Manager → **Add Roles and Features** → Server Roles

Dans l'arborescence **File and Storage Services** :

```
File and Storage Services
└── File and iSCSI Services
    ├── File Server (Installed)
    ├── BranchCache for Network Files
    ├── Data Deduplication
    ├── DFS Namespaces
    ├── DFS Replication
    ├── File Server Resource Manager    ← Cocher ici
    ├── File Server VSS Agent Service
    └── iSCSI Target Server
```

> FSRM n'est **pas installé par défaut** avec le rôle File Server. Il doit être ajouté explicitement. La description précise qu'il permet de planifier des tâches de gestion de fichiers, configurer des quotas de dossiers et définir des politiques de filtrage de fichiers.

![Installation FSRM](../../docs/assets/Windows_server_AD/limitations/1.png)

---

## 2. Découverte des templates de quotas par défaut

Une fois FSRM installé, ouvrir la console via **Tools → File Server Resource Manager**.

**Accès :** FSRM → **Quota Management** → **Quota Templates**

FSRM propose une liste de **templates prédéfinis** :

| Quota Template | Limit | Quota Type |
|----------------|-------|------------|
| 10 GB Limit | 10.0 GB | Hard |
| 100 MB Limit | 100 MB | Hard |
| 2 GB Limit | 2.00 GB | Hard |
| 200 MB Limit Reports to User | 200 MB | Hard |
| 200 MB Limit with 50 MB Extension | 200 MB | Hard |
| 250 MB Extended Limit | 250 MB | Hard |
| 5 GB Limit | 5.00 GB | Hard |
| Monitor 10 TB Volume Usage | 10.0 TB | **Soft** |
| Monitor 200 GB Volume Usage | 200 GB | **Soft** |
| Monitor 3 TB Volume Usage | 3.00 TB | **Soft** |
| Monitor 5 TB Volume Usage | 5.00 TB | **Soft** |
| Monitor 500 MB Share | 500 MB | **Soft** |

> **Hard quota** : empêche physiquement l'écriture au-delà de la limite.  
> **Soft quota** : surveille l'usage et génère des alertes sans bloquer l'écriture.  
> Aucun de ces templates ne correspond exactement aux besoins (2 GB avec notification personnalisée) → création d'un template dédié.

![FSRM — Quota Templates par défaut](../../docs/assets/Windows_server_AD/limitations/2.png)

---

## 3. Création d'un template de quota personnalisé — Perso

Un template personnalisé est créé pour les dossiers personnels des utilisateurs.

**Procédure :** Clic droit sur **Quota Templates** → **Create Quota Template...**

| Paramètre | Valeur |
|-----------|--------|
| **Copy properties from** | `2 GB Limit` *(base de départ)* |
| **Template name** | `Perso` |
| **Description** | *(vide)* |
| **Space limit** | `2` GB |
| **Quota type** | **Hard quota** — Do not allow users to exceed limit |

> Partir du template `2 GB Limit` existant permet de récupérer sa structure de base. Le nom `Perso` identifie clairement l'usage (dossiers personnels). Le type **Hard** est choisi pour bloquer strictement les dépassements.

![Création template Perso — 2 GB Hard](../../docs/assets/Windows_server_AD/limitations/3.png)

---

## 4. Configuration du seuil de notification (Threshold 85%)

Dans la section **Notification thresholds**, cliquer sur **Add...** pour définir une alerte.

| Paramètre | Valeur |
|-----------|--------|
| **Seuil de déclenchement** | `85` % |
| **E-mail Message** | *(configurable)* |
| **Send e-mail to administrators** | *(optionnel)* |
| **Send e-mail to the user who exceeded** | *(optionnel)* |

**Variables disponibles dans le message e-mail :**
- `[Quota Threshold]%` — pourcentage du seuil atteint
- `[Quota Path]` — chemin du dossier concerné
- `[Server]` — nom du serveur
- `[Quota Limit MB]` — limite en Mo
- `[Quota Used MB]` — espace utilisé en Mo
- `[Quota Used Percent]` — pourcentage utilisé

> À 85% d'utilisation (1.7 GB sur 2 GB), une notification est déclenchée. D'autres seuils peuvent être ajoutés (ex. 95%) pour une escalade progressive. L'onglet **Event Log** permet également d'enregistrer l'alerte dans le journal Windows.

![Add Threshold — 85% avec options e-mail](../../docs/assets/Windows_server_AD/limitations/4.png)
---

## 5. Vérification du template Perso dans la liste

Après création, le template `Perso` apparaît dans la liste des **Quota Templates** :

| Quota Template | Limit | Quota Type |
|----------------|-------|------------|
| ... *(templates existants)* | ... | ... |
| **Perso** | **2.00 GB** | **Hard** |

> Le template est prêt à être utilisé pour créer des quotas sur les dossiers cibles.

![Quota Templates — Perso ajouté](../../docs/assets/Windows_server_AD/limitations/5.png)

---

## 6. Création d'un quota sur le dossier PERSONNELS

**Accès :** FSRM → **Quota Management** → **Quotas** → clic droit → **Create Quota...**

Le menu contextuel propose **Create Quota...** pour démarrer l'assistant d'application du quota.

![Quotas — Menu Create Quota](../../docs/assets/Windows_server_AD/limitations/6.png)

---

## 7. Sélection du dossier cible

Dans la boîte **Create Quota**, cliquer sur **Browse...** pour sélectionner le dossier.

**Arborescence affichée :**

```
This PC
└── New Volume (B:)
    └── PERSONNELS          ← Sélectionner ici
        ├── ASHELBY
        ├── JDOUGS
        └── TSHELBY
    └── SHELBY.CO
```

**Dossier sélectionné :** `PERSONNELS`

> En sélectionnant le dossier **parent** `PERSONNELS` (et non un sous-dossier individuel), l'option **Auto apply** permettra d'appliquer le quota automatiquement à tous les sous-dossiers existants et futurs.

![Browse For Folder — Sélection PERSONNELS](../../docs/assets/Windows_server_AD/limitations/7.png)

---

## 8. Configuration finale et application automatique

De retour dans **Create Quota**, configurer les options d'application :

| Paramètre | Valeur |
|-----------|--------|
| **Quota path** | `B:\PERSONNELS` |
| **Mode** | **Auto apply template and create quotas on existing and new subfolders** |
| **Source template** | `Perso` |

**Résumé des propriétés appliquées :**

```
Auto Apply Quota: B:\PERSONNELS
├── Source template: Perso
├── Limit: 2.00 GB (Hard)
└── Notification: 2
    └── Warning(85%):
```

> Le mode **Auto apply** est crucial : il crée automatiquement un quota de 2 GB sur **chaque sous-dossier** existant (ASHELBY, JDOUGS, TSHELBY) et sur **tout nouveau sous-dossier** créé ultérieurement dans `PERSONNELS`. Cliquer sur **Create** pour valider.

![Create Quota — Auto Apply, template Perso](../../docs/assets/Windows_server_AD/limitations/8.png)

---

## 9. Vérification — Quotas actifs sur les sous-dossiers

Après création, la vue **Quotas** liste les 4 entrées générées automatiquement :

**Groupe : Source Template: Perso (4 items)**

| Quota Path | % Used | Limit | Quota Type | Source Template | Match Template |
|------------|--------|-------|------------|----------------|----------------|
| `B:\PERSONNELS\*` | --- | 2.00 GB | Hard (Auto Apply) | Perso | Yes |
| `B:\PERSONNELS\ASHELBY` | 0% | 2.00 GB | Hard | Perso | Yes |
| `B:\PERSONNELS\JDOUGS` | 0% | 2.00 GB | Hard | Perso | Yes |
| `B:\PERSONNELS\TSHELBY` | 0% | 2.00 GB | Hard | Perso | Yes |

> L'entrée `B:\PERSONNELS\*` est la règle **Auto Apply** parent qui génère automatiquement les quotas enfants. Chaque utilisateur dispose d'une limite stricte de **2 GB** sur son dossier personnel. Le `Match Template: Yes` indique que les quotas sont synchronisés avec le template — toute modification du template `Perso` se propagera automatiquement.

![Quotas actifs — 4 entrées Auto Apply Perso](../../docs/assets/Windows_server_AD/limitations/9.png)

---

## 10. Validation côté client — Espace limité visible

Sur le poste client **Windows 10** connecté avec le compte `TSHELBY`, l'Explorateur Windows affiche les lecteurs réseau avec l'espace correct :

**Network locations (2) :**

| Lecteur | Chemin | Espace libre | Taille totale |
|---------|--------|-------------|---------------|
| PEAKY-BLINDERS (B:) | `\\DC25\shelby.co` | 99.3 GB | 99.9 GB |
| **TSHELBY (\\Dc25\personnels) (Z:)** | `\\Dc25\personnels\TSHELBY` | **1.99 GB** | **2.00 GB** |

> ✅ Le quota est effectif et visible depuis le client : le lecteur `Z:` affiche bien une capacité totale de **2.00 GB** — la limite du template `Perso`. Le lecteur `B:` (SHELBY.CO) n'a pas de quota et affiche la capacité complète du volume.

![Client Windows 10 — Z: limité à 2 GB](../../docs/assets/Windows_server_AD/limitations/10.png)

---

## 11. Test de dépassement — Quota Hard en action

Pour valider le blocage effectif, une tentative de copie d'un fichier de **3.00 GB** vers le lecteur `Z:` est effectuée depuis le bureau du client.

**Message d'erreur Windows :**

> *"There is not enough space on TSHELBY (\\Dc25\personnels)"*  
> *3.00 GB is needed to copy this item. Delete or move files so you have enough space.*

**Détails affichés :**
- **Destination :** TSHELBY (\\Dc25\personnels)
- **Space free :** 1.99 GB
- **Total size :** 2.00 GB

> ✅ Le **Hard Quota** fonctionne correctement : Windows bloque la copie du fichier (3 GB > 2 GB disponibles) et affiche un message d'erreur explicite. L'utilisateur ne peut pas contourner cette limite — contrairement à un Soft Quota qui n'aurait fait que générer une alerte.

![Test quota — Copie bloquée, 3 GB refusé](../../docs/assets/Windows_server_AD/limitations/11.png)

---


## Remarques

- L'option **Auto apply** est la bonne pratique pour les dossiers personnels : elle garantit que tout nouvel utilisateur (nouveau sous-dossier) bénéficiera automatiquement du quota sans intervention manuelle.
- La synchronisation **Match Template: Yes** permet de modifier la limite globalement en éditant uniquement le template `Perso` — tous les quotas liés se mettent à jour automatiquement.
- En production, il est recommandé de configurer les **notifications e-mail** avec une adresse SMTP valide pour alerter les administrateurs et/ou les utilisateurs avant le dépassement.

---

