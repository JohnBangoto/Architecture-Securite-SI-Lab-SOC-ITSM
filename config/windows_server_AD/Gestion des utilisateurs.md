# 🏢 Configuration Active Directory — Windows Server 2025

> **Contexte :** Mise en place de la structure organisationnelle de la société fictive **PEAKY-BLINDERS** / **SHELBY.CO**

---

## Partie A — Active Directory

### 1. Vérification du contrôleur de domaine

Avant toute configuration, vérifier que le contrôleur de domaine est bien opérationnel dans **Active Directory Users and Computers** (ADUC).

**Accès :** Server Manager → Tools → **Active Directory Users and Computers**

Dans l'OU **Domain Controllers** :

| Name | Type | DC Type | Site |
|------|------|---------|------|
| DC25 | Computer | GC (Global Catalog) | Default-First-Site |

> Le serveur `DC25` est bien enregistré comme **Global Catalog**, rôle requis pour l'authentification dans le domaine `lab.local`.

![ADUC — Domain Controllers](<../../docs/assets/Windows_server_AD/Gestions des users/1.png>)

---

### 2. Création de l'OU racine PEAKY-BLINDERS

La première étape consiste à créer l'**Unité d'Organisation (OU)** racine qui regroupera l'ensemble des objets de la société.

**Procédure :**
- Clic droit sur `lab.local` → **New** → **Organizational Unit**
- Saisir le nom : `PEAKY-BLINDERS`
- Laisser coché **"Protect container from accidental deletion"**
- Cliquer sur **OK**

> La protection contre la suppression accidentelle est activée par défaut — bonne pratique à conserver en production.

![Création OU PEAKY-BLINDERS](<../../docs/assets/Windows_server_AD/Gestions des users/2.png>)

---

### 3. Structure complète des OUs

Après création de l'OU racine, créer les **sous-OUs** suivantes par le même procédé (clic droit sur `PEAKY-BLINDERS` → New → Organizational Unit) :

```
lab.local
└── PEAKY-BLINDERS
    ├── Direction
    ├── IT
    ├── Vente
    └── PC               ← Conteneur pour les postes de travail
```

La vue ADUC confirme la présence des 4 sous-OUs.

![Structure des OUs PEAKY-BLINDERS](<../../docs/assets/Windows_server_AD/Gestions des users/3.png>)

---

### 4. Création des utilisateurs

Les utilisateurs sont créés dans l'OU `PEAKY-BLINDERS` (puis déplacés dans leur OU métier respective).

**Procédure :** Clic droit sur l'OU cible → **New** → **User**

**Utilisateurs créés :**

| Nom complet | Logon UPN | OU cible | Groupe |
|-------------|-----------|----------|--------|
| THOMAS TS. SHELBY | `TSHELBY@lab.local` | Direction | DR-GP |
| ARTHUR AS. SHELBY | `ASHELBY@lab.local` | Direction | DR-GP |
| JOHNNY JD. DOGS | `JDOGS@lab.local` | Vente | VT-GP |

> L'option **"User must change password at next logon"** est activée par défaut — recommandé pour un premier déploiement.

L'écran de confirmation affiche le résumé avant création :

![Confirmation création utilisateur TSHELBY](<../../docs/assets/Windows_server_AD/Gestions des users/4.png>)

---

### 5. Création des groupes de sécurité

Trois groupes de sécurité sont créés dans l'OU `PEAKY-BLINDERS` pour gérer les accès aux ressources partagées.

**Procédure :** Clic droit sur `PEAKY-BLINDERS` → **New** → **Group**

| Groupe | Scope | Type | Rôle |
|--------|-------|------|------|
| **DR-GP** | Global | Security | Utilisateurs Direction |
| **IT-GP** | Global | Security | Utilisateurs IT |
| **VT-GP** | Global | Security | Utilisateurs Vente |

**Paramètres appliqués à tous les groupes :**
- **Group scope :** Global *(portée domaine, recommandé pour les groupes métiers)*
- **Group type :** Security *(gestion des permissions, pas Distribution)*

![Création groupe DR-GP](<../../docs/assets/Windows_server_AD/Gestions des users/5.png>)

---

### 6. Vue d'ensemble — OUs, groupes et utilisateurs

La vue complète de l'OU `PEAKY-BLINDERS` confirme la présence de tous les objets créés :

**OUs (Organizational Units) :**
- Direction, IT, Vente, PC

**Groupes de sécurité :**
- DR-GP, IT-GP, VT-GP

**Utilisateurs :**
- THOMAS TS... (SHELBY)
- ARTHUR AS... (SHELBY)
- JOHNNY JD... (DOGS)

![Vue complète PEAKY-BLINDERS](<../../docs/assets/Windows_server_AD/Gestions des users/6.png>)

---

### 7. Attribution des utilisateurs aux groupes

Une fois les utilisateurs et groupes créés, les membres sont assignés à leur groupe respectif.

**Procédure :** Clic droit sur le groupe → **Properties** → onglet **Members** → **Add**

| Utilisateur | Groupe assigné | Justification |
|-------------|---------------|---------------|
| THOMAS TS. SHELBY (`TSHELBY`) | **DR-GP** | Membre de la Direction |
| ARTHUR AS. SHELBY (`ASHELBY`) | **DR-GP** | Membre de la Direction |
| JOHNNY JD. DOGS (`JDOGS`) | **VT-GP** | Membre de la Vente |

> Les groupes `DR-GP`, `IT-GP` et `VT-GP` seront utilisés pour l'attribution des permissions NTFS sur les dossiers partagés du volume B: (voir Partie B).

---

### 8. Redirection du conteneur Computers vers l'OU PC

Par défaut, lorsqu'un poste rejoint le domaine, il est placé dans le conteneur `CN=Computers` (non une OU). Pour qu'il atterrisse automatiquement dans l'OU `PC`, exécuter la commande suivante en **PowerShell (Admin)** :

```powershell
RedirCmp "OU=PC,OU=PEAKY-BLINDERS,DC=lab,DC=local"
```

**Résultat :**
```
Redirection was successful.
```

> Désormais, tout ordinateur qui joint le domaine `lab.local` sera automatiquement placé dans `PEAKY-BLINDERS > PC` au lieu de `Computers`.

![RedirCmp — Redirection Computers vers OU PC](<../../docs/assets/Windows_server_AD/Gestions des users/7.png>)

---

## Partie B — Stockage & Partages réseau

### 9. Ajout d'un disque virtuel SATA (VMware)

Un second disque est ajouté à la VM pour héberger les partages réseau sur un volume dédié, séparé du disque système.

**Procédure VMware :** VM Settings → **Add** → sélectionner le type de disque

| Paramètre | Valeur |
|-----------|--------|
| **Type de disque** | SATA *(sélectionné)* |
| **Taille** | `100 Go` |
| **Stockage** | Fichier unique *(meilleures performances)* |
| **Taille recommandée Windows Server 2025** | 60 Go |

> Le choix **SATA** est le plus compatible pour les VM Windows Server. La taille de 100 Go dépasse la recommandation minimale afin d'anticiper la croissance des données partagées.

![Ajout disque SATA — Type](<../../docs/assets/Windows_server_AD/Gestions des users/8.png>)

![Ajout disque SATA — Taille 100 Go](<../../docs/assets/Windows_server_AD/Gestions des users/9.png>)

---

### 10. Initialisation et formatage du disque (Disk Management)

Une fois le disque ajouté, l'initialiser et créer un volume depuis **Disk Management** (`diskmgmt.msc`).

**Résumé de configuration du New Simple Volume Wizard :**

| Paramètre | Valeur |
|-----------|--------|
| **Volume type** | Simple Volume |
| **Disk** | Disk 1 |
| **Volume size** | 102 382 MB (~100 Go) |
| **Drive letter** | `B:` |
| **File system** | NTFS |
| **Allocation unit size** | Default |
| **Volume label** | New Volume |
| **Quick format** | Yes |

> La lettre `B:` est attribuée au nouveau volume pour le distinguer clairement du disque système `C:`.

![New Simple Volume Wizard — Finalisation](<../../docs/assets/Windows_server_AD/Gestions des users/10.png>)

---

### 11. Création des dossiers partagés

Sur le volume `B:`, deux dossiers principaux sont créés pour les partages réseau :

| Dossier | Chemin | Rôle |
|---------|--------|------|
| **PERSONNELS** | `B:\PERSONNELS` | Dossiers personnels des utilisateurs |
| **SHELBY.CO** | `B:\SHELBY.CO` | Dossiers métiers par département |

**Structure complète :**

```
B:\
├── PERSONNELS\
└── SHELBY.CO\
    ├── Direction\
    ├── IT\
    └── Vente\
```

![Volume B: avec PERSONNELS et SHELBY.CO](<../../docs/assets/Windows_server_AD/Gestions des users/11.png>)

![SHELBY.CO — sous-dossiers Direction, IT, Vente](<../../docs/assets/Windows_server_AD/Gestions des users/12.png>)

---

### 12. Permissions de partage (Share Permissions) — PERSONNELS

Les **Share Permissions** contrôlent l'accès au dossier lors d'une connexion réseau (UNC `\\serveur\partage`).

**Accès :** Clic droit sur le dossier → **Properties** → onglet **Sharing** → **Advanced Sharing** → **Permissions**

#### Domain Admins (LAB\Domain Admins)

| Permission | Allow | Deny |
|------------|-------|------|
| Full Control | ✅ | ☐ |
| Change | ✅ | ☐ |
| Read | ✅ | ☐ |

![Share Permissions — Domain Admins](<../../docs/assets/Windows_server_AD/Gestions des users/13.png>)

#### Domain Users (LAB\Domain Users)

| Permission | Allow | Deny |
|------------|-------|------|
| Full Control | ☐ | ☐ |
| Change | ✅ | ☐ |
| Read | ✅ | ☐ |

> Les **Domain Users** ont `Change + Read` — ils peuvent lire et modifier les fichiers mais pas changer les permissions ni supprimer le dossier partagé.

![Share Permissions — Domain Users](<../../docs/assets/Windows_server_AD/Gestions des users/14.png>)

> ⚠️ Les Share Permissions s'appliquent **uniquement** lors d'un accès réseau. Les permissions NTFS s'appliquent toujours (en local et en réseau). C'est le **cumul le plus restrictif** des deux qui s'applique.

---

### 13. Permissions NTFS — Blocage de l'héritage

Par défaut, le dossier `PERSONNELS` hérite des permissions de `B:\`, ce qui inclut le groupe `Users (LAB\Users)` avec des droits étendus non souhaités.

**Étape 1 — Tentative de suppression directe :**

La suppression de `Users (LAB\Users)` échoue avec le message :

> *"You can't remove Users (LAB\Users) because this object is inheriting permissions from its parent."*

![Erreur suppression Users hérités](<../../docs/assets/Windows_server_AD/Gestions des users/15.png>)

**Étape 2 — Désactiver l'héritage :**

Cliquer sur **Disable inheritance** → choisir :

> **"Convert inherited permissions into explicit permissions on this object"**

> Cette option convertit les droits hérités en permissions explicites, permettant ensuite de les modifier ou supprimer individuellement.

![Block Inheritance — choix de conversion](<../../docs/assets/Windows_server_AD/Gestions des users/16.png>)

---

### 14. Permissions NTFS après blocage — PERSONNELS

Après blocage de l'héritage et suppression des entrées non souhaitées (`Users (LAB\Users)`), les permissions NTFS finales du dossier `B:\PERSONNELS` sont :

| Principal | Type | Access | Inherited from | Applies to |
|-----------|------|--------|----------------|------------|
| Administrators (LAB\Administ...) | Allow | Full control | None | This folder, subfolders and files |
| SYSTEM | Allow | Full control | None | This folder, subfolders and files |
| CREATOR OWNER | Allow | Full control | None | Subfolders and files only |

> Le groupe `Users (LAB\Users)` a été supprimé. Seuls les administrateurs, SYSTEM et le propriétaire créateur conservent des droits. Les permissions des groupes métiers (DR-GP, IT-GP, VT-GP) sont ajoutées individuellement selon les besoins.

![NTFS PERSONNELS — Permissions après blocage héritage](<../../docs/assets/Windows_server_AD/Gestions des users/17.png>)

> La même procédure de blocage d'héritage est appliquée au dossier **SHELBY.CO** et à ses sous-dossiers pour garantir un contrôle granulaire des accès.

---

### 15. Structure des dossiers SHELBY.CO

Le dossier `SHELBY.CO` contient trois sous-dossiers correspondant aux départements de la société, dont les permissions NTFS sont configurées indépendamment :

```
B:\SHELBY.CO\
├── Direction\    ← Accessible au groupe DR-GP
├── IT\           ← Accessible au groupe IT-GP
└── Vente\        ← Accessible au groupe VT-GP
```

![SHELBY.CO — Direction, IT, Vente](<../../docs/assets/Windows_server_AD/Gestions des users/18.png>)

---

### 16. Permissions NTFS — SHELBY.CO (accès racine)

Pour le dossier racine `B:\SHELBY.CO`, les utilisateurs du domaine reçoivent uniquement la permission de **traverser** le dossier (sans accès aux fichiers), afin qu'ils puissent accéder à leur sous-dossier métier.

**Principal :** `Users (LAB\Users)`  
**Type :** Allow  
**Applies to :** This folder only *(pas de propagation aux sous-dossiers)*

| Permission avancée | Accordée |
|--------------------|----------|
| Traverse folder / execute file | ✅ |
| List folder / read data | ✅ |
| Read attributes | ✅ |
| Read extended attributes | ✅ |
| Read permissions | ✅ |
| Full control | ☐ |
| Create files / write data | ☐ |
| Create folders / append data | ☐ |
| Write attributes | ☐ |
| Delete | ☐ |

> Ce niveau de permission (**"This folder only"**) permet à un utilisateur de voir la liste des sous-dossiers sans pouvoir créer, modifier ou supprimer quoi que ce soit à la racine. L'accès réel est défini au niveau des sous-dossiers par groupe.

![Permission Entry SHELBY.CO — Users lecture seule racine](<../../docs/assets/Windows_server_AD/Gestions des users/19.png>)

---

### 17. Permissions NTFS — Sous-dossier Direction (DR-GP)

Le sous-dossier `Direction` est configuré pour être accessible en **lecture/écriture** uniquement aux membres du groupe `DR-GP`.

**Principal :** `DR-GP (LAB\DR-GP)`  
**Type :** Allow  
**Applies to :** This folder, subfolders and files

| Permission de base | Accordée |
|--------------------|----------|
| Full control | ☐ |
| Modify | ☐ |
| Read & execute | ✅ |
| List folder contents | ✅ |
| Read | ✅ |
| Write | ✅ |

> La combinaison **Read & execute + List + Read + Write** permet aux membres de `DR-GP` de lire, créer et modifier des fichiers dans `Direction`, sans pouvoir supprimer le dossier lui-même ni modifier les permissions.  
> La **même configuration** est appliquée aux dossiers `IT` (groupe `IT-GP`) et `Vente` (groupe `VT-GP`).

![Permission Entry Direction — DR-GP](<../../docs/assets/Windows_server_AD/Gestions des users/20.png>)

---

---

## 18. Permissions NTFS — Sous-dossier IT (IT-GP)

Le sous-dossier `IT` reçoit les mêmes permissions d'écriture que `Direction`, mais restreintes au groupe `IT-GP`.

**Principal :** `IT-GP (LAB\IT-GP)`  
**Type :** Allow  
**Applies to :** This folder, subfolders and files

| Permission avancée | Accordée |
|--------------------|----------|
| Traverse folder / execute file | ✅ |
| List folder / read data | ✅ |
| Read attributes | ✅ |
| Read extended attributes | ✅ |
| Create files / write data | ✅ |
| Create folders / append data | ✅ |
| Write attributes | ✅ |
| Write extended attributes | ✅ |
| Read permissions | ✅ |
| Full control | ☐ |
| Delete subfolders and files | ☐ |
| Delete | ☐ |
| Change permissions | ☐ |
| Take ownership | ☐ |

> Seul le groupe `IT-GP` a accès en lecture/écriture au dossier `IT`. Les membres des autres groupes (DR-GP, VT-GP) ne peuvent pas y accéder.

![Permission Entry IT — IT-GP](<../../docs/assets/Windows_server_AD/Gestions des users/21.png>)

---

## 19. Permissions NTFS — Sous-dossier Vente (VT-GP)

Le sous-dossier `Vente` suit la même configuration, avec le groupe `VT-GP` comme principal.

**Principal :** `VT-GP (LAB\VT-GP)`  
**Type :** Allow  
**Applies to :** This folder, subfolders and files

| Permission avancée | Accordée |
|--------------------|----------|
| Traverse folder / execute file | ✅ |
| List folder / read data | ✅ |
| Read attributes | ✅ |
| Read extended attributes | ✅ |
| Create files / write data | ✅ |
| Create folders / append data | ✅ |
| Write attributes | ✅ |
| Write extended attributes | ✅ |
| Read permissions | ✅ |
| Full control | ☐ |
| Delete subfolders and files | ☐ |
| Delete | ☐ |
| Change permissions | ☐ |
| Take ownership | ☐ |

> La cloisonnement est strict : chaque groupe ne voit et n'accède qu'à son propre dossier métier grâce à la combinaison **Access-based enumeration** (côté partage) + **permissions NTFS granulaires** (côté système de fichiers).

![Permission Entry Vente — VT-GP](<../../docs/assets/Windows_server_AD/Gestions des users/22.png>)

---

## 20. Vue d'ensemble des partages SMB (Server Manager)

**Accès :** Server Manager → **File and Storage Services** → **Shares**

La console liste les **4 partages SMB** actifs sur le serveur `DC25` :

| Share | Local Path | Protocol | Type |
|-------|------------|----------|------|
| **NETLOGON** | `C:\WINDOWS\SYSVOL\sysvol\lab.l...` | SMB | Not Clustered |
| **PERSONNELS** | `B:\PERSONNELS` | SMB | Not Clustered |
| **SHELBY.CO** | `B:\SHELBY.CO` | SMB | Not Clustered |
| **SYSVOL** | `C:\WINDOWS\SYSVOL\sysvol` | SMB | Not Clustered |

> `NETLOGON` et `SYSVOL` sont des partages système créés automatiquement lors de la promotion du serveur en contrôleur de domaine. `PERSONNELS` et `SHELBY.CO` sont les partages métiers créés manuellement sur le volume `B:`.

![Server Manager — Liste des partages SMB](<../../docs/assets/Windows_server_AD/Gestions des users/23.png>)

---

## 21. Paramètres avancés du partage SHELBY.CO

Dans les propriétés du partage `SHELBY.CO`, l'onglet **Settings** expose des options importantes :

| Option | État | Description |
|--------|------|-------------|
| **Enable access-based enumeration** | ✅ Activé | Masque les dossiers auxquels l'utilisateur n'a pas accès |
| **Allow caching of share** | ✅ Activé | Permet la mise en cache pour les utilisateurs hors ligne |
| **Enable BranchCache** | ☐ Désactivé | Non requis (pas de site distant) |
| **Encrypt data access** | ☐ Désactivé | Chiffrement SMB non requis dans ce lab |

> L'**Access-based enumeration (ABE)** est une option cruciale en production : un utilisateur du groupe `VT-GP` qui accède à `\\DC25\shelby.co` ne verra que le dossier `Vente` — les dossiers `Direction` et `IT` seront invisibles pour lui. Cela renforce la confidentialité sans messages d'erreur d'accès refusé.

![SHELBY.CO Properties — Settings](<../../docs/assets/Windows_server_AD/Gestions des users/24.png>)

---

## Partie C — Dossiers personnels & GPO

### 22. Attribution du Home Folder aux utilisateurs

Pour que chaque utilisateur dispose d'un **dossier personnel** monté automatiquement à la connexion, configurer le **Home Folder** dans les propriétés du compte AD.

**Procédure (multi-sélection) :**
1. Dans ADUC, sélectionner les 3 utilisateurs simultanément (ARTHUR AS., JOHNNY JD., THOMAS TS.)
2. Clic droit → **Properties** → onglet **Profile**
3. Dans **Home folder** → cocher **Connect**

| Paramètre | Valeur |
|-----------|--------|
| **Connect** | ✅ |
| **Drive letter** | `Z:` |
| **To (chemin UNC)** | `\\Dc25\personnels\%username%` |

> La variable `%username%` est automatiquement remplacée par le logon name de chaque utilisateur lors de l'application. Windows crée le sous-dossier personnel à la première connexion.

![Home Folder — Configuration multi-utilisateurs](<../../docs/assets/Windows_server_AD/Gestions des users/25.png>)

---

### 23. Création automatique des dossiers personnels

Après application du Home Folder, Windows Server crée automatiquement les sous-dossiers correspondants dans `B:\PERSONNELS`.

Le dossier `PERSONNELS` contient désormais :

| Dossier | Date de création | Type |
|---------|-----------------|------|
| `ASHELBY` | 3/24/2026 9:20 AM | File folder |
| `JDOUGS` | 3/24/2026 9:15 AM | File folder |
| `TSHELBY` | 3/24/2026 9:15 AM | File folder |

**Message de confirmation AD :**
> *"All changes on the following tabs were successfully applied: General"*

> Les erreurs indiquées pour JOHNNY JD. et THOMAS TS. (`The %1 home folder was not created because it already exists`) confirment que les dossiers existaient déjà — comportement normal si l'opération est rejouée.

![Dossiers personnels créés automatiquement](<../../docs/assets/Windows_server_AD/Gestions des users/26.png>)

---

### 24. Attribution des utilisateurs aux groupes (Select Groups)

Pour ajouter un utilisateur à un groupe, utiliser la boîte **Select Groups** depuis les propriétés du compte utilisateur → onglet **Member Of** → **Add**.

**Exemple — Ajout au groupe DR-GP :**

| Paramètre | Valeur |
|-----------|--------|
| **Object type** | Groups or Built-in security principals |
| **Location** | `lab.local` |
| **Object name** | `DR-GP` |

Cliquer **Check Names** pour valider la résolution, puis **OK**.

> Cette procédure est répétée pour chaque utilisateur selon le tableau d'appartenance :  
> `TSHELBY` → DR-GP | `ASHELBY` → DR-GP | `JDOUGS` → VT-GP

![Select Groups — Ajout DR-GP](<../../docs/assets/Windows_server_AD/Gestions des users/27.png>)

---

### 25. Création de la GPO GARRISON

Une **Group Policy Object (GPO)** nommée `GARRISON` est créée et liée à l'OU `PEAKY-BLINDERS` pour déployer automatiquement les lecteurs réseau sur les postes clients.

**Accès :** Outils d'administration → **Group Policy Management**

**Procédure :**
1. Clic droit sur l'OU `PEAKY-BLINDERS` → **Create a GPO in this domain, and Link it here...**
2. Nommer la GPO : `GARRISON`
3. Source Starter GPO : `(none)`
4. Cliquer **OK**

> La GPO est automatiquement liée à `PEAKY-BLINDERS` et s'appliquera à tous les objets de cette OU (utilisateurs et ordinateurs selon la configuration).

![Création GPO GARRISON liée à PEAKY-BLINDERS](<../../docs/assets/Windows_server_AD/Gestions des users/28.png>)

---

### 26. Configuration Drive Maps dans la GPO GARRISON

Dans l'éditeur de la GPO `GARRISON`, configurer le **mappage automatique** du lecteur réseau `SHELBY.CO`.

**Chemin :** User Configuration → Preferences → Windows Settings → **Drive Maps** → New Drive

| Paramètre | Valeur |
|-----------|--------|
| **Action** | Update |
| **Location** | `\\Dc25\shelby.co` |
| **Label as** | `PEAKY-BLINDERS` |
| **Drive Letter** | `B:` (Use: B) |
| **Reconnect** | ☐ |
| **Hide/Show this drive** | No change |
| **Hide/Show all drives** | No change |

> Ce Drive Map monte automatiquement le partage `\\Dc25\shelby.co` en lecteur `B:` avec le label `PEAKY-BLINDERS` pour tous les utilisateurs de l'OU `PEAKY-BLINDERS` à leur connexion. Combiné avec l'ABE, chaque utilisateur ne voit que son propre sous-dossier métier.

![GPO GARRISON — Drive Maps SHELBY.CO](<../../docs/assets/Windows_server_AD/Gestions des users/29.png>)

---

### 27. Validation — Connexion utilisateur domaine

Pour valider la configuration, ouvrir une session sur un **poste client Windows 10** joint au domaine avec un compte utilisateur du domaine.

**Écran de connexion :**

| Champ | Valeur |
|-------|--------|
| **Utilisateur** | `ASHELBY` |
| **Domaine** | `LAB` (affiché : *Sign in to: LAB*) |

> L'écran affiche **"Sign in to: LAB"**, confirmant que le poste est bien joint au domaine `lab.local` et que l'authentification se fait contre le contrôleur de domaine `DC25`. Lors de cette première connexion, le mot de passe est changé (option activée à la création).

![Écran de connexion domaine — ASHELBY](<../../docs/assets/Windows_server_AD/Gestions des users/30.png>)

---

### 28. Validation — Lecteurs réseau montés sur le client

Après connexion avec le compte `TSHELBY`, l'**Explorateur Windows** du poste client affiche les lecteurs réseau montés automatiquement par la GPO et le Home Folder :

**Network locations (2) :**

| Lecteur | Chemin UNC | Espace libre |
|---------|-----------|--------------|
| **PEAKY-BLINDERS (B:)** | `\\DC25\shelby.co` | 99.8 GB / 99.9 GB |
| **TSHELBY (\\Dc25\personnels) (Z:)** | `\\Dc25\personnels\TSHELBY` | 99.8 GB / 99.9 GB |

> ✅ La validation est concluante :
> - Le lecteur `B:` (SHELBY.CO) est monté via la **GPO GARRISON**
> - Le lecteur `Z:` (dossier personnel TSHELBY) est monté via le **Home Folder AD**
> - Les deux lecteurs pointent vers le volume `B:` du serveur DC25 (100 Go disponibles)

![Client Windows 10 — Lecteurs réseau B: et Z: montés](<../../docs/assets/Windows_server_AD/Gestions des users/31.png>)

---

## Récapitulatif de la structure AD et des partages

### Structure Active Directory

```
lab.local
└── PEAKY-BLINDERS (OU)
    ├── Direction (OU)
    ├── IT (OU)
    ├── Vente (OU)
    ├── PC (OU)              ← Cible RedirCmp
    ├── DR-GP (Security Group - Global)  ← TSHELBY, ASHELBY
    ├── IT-GP (Security Group - Global)
    ├── VT-GP (Security Group - Global)  ← JDOUGS
    ├── THOMAS TS. SHELBY    → DR-GP | Home: Z: → \\Dc25\personnels\TSHELBY
    ├── ARTHUR AS. SHELBY    → DR-GP | Home: Z: → \\Dc25\personnels\ASHELBY
    └── JOHNNY JD. DOGS      → VT-GP | Home: Z: → \\Dc25\personnels\JDOUGS
```

### Matrice des permissions — Dossiers partagés

| Dossier | Groupe | Share (réseau) | NTFS |
|---------|--------|----------------|------|
| `B:\PERSONNELS` | Domain Admins | Full Control | Full Control |
| `B:\PERSONNELS` | Domain Users | Change + Read | *(par sous-dossier)* |
| `B:\SHELBY.CO` | LAB\Users | — | Traverse only (racine) |
| `B:\SHELBY.CO\Direction` | DR-GP | — | Read + Write (avancé) |
| `B:\SHELBY.CO\IT` | IT-GP | — | Read + Write (avancé) |
| `B:\SHELBY.CO\Vente` | VT-GP | — | Read + Write (avancé) |

### Lecteurs réseau montés sur les clients

| Lecteur | Source | Chemin | Mécanisme |
|---------|--------|--------|-----------|
| `B:` | SHELBY.CO | `\\DC25\shelby.co` | GPO GARRISON (Drive Maps) |
| `Z:` | PERSONNELS | `\\Dc25\personnels\%username%` | Home Folder AD |

### GPO — GARRISON

| Paramètre | Valeur |
|-----------|--------|
| **Nom** | `GARRISON` |
| **Liée à** | OU `PEAKY-BLINDERS` |
| **Type de politique** | User Configuration → Preferences → Drive Maps |
| **Action** | Update |
| **Partage mappé** | `\\Dc25\shelby.co` → `B:` (label: PEAKY-BLINDERS) |

---

## Remarques

- Le blocage d'héritage (`Disable inheritance`) est une étape critique pour isoler les permissions des dossiers partagés et éviter que des droits trop larges se propagent depuis la racine du volume.
- La commande `RedirCmp` doit être exécutée **une seule fois** par domaine — elle modifie un attribut de l'objet `WellKnown Objects` dans AD.
- Les groupes de type **Global Security** sont le choix standard pour les groupes métiers dans un environnement à domaine unique.
- L'**Access-based enumeration** sur `SHELBY.CO` est essentielle : elle masque les sous-dossiers inaccessibles, évitant les messages d'accès refusé et renforçant la confidentialité.
- La variable `%username%` dans le Home Folder est résolue côté serveur — Windows crée automatiquement le sous-dossier personnel à la première connexion de l'utilisateur.

---

