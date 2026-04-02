# 🖨️ Configuration du Serveur d'Impression — Windows Server 2025

> **Environnement :** Windows Server 2025 — Domaine `lab.local` — Serveur `DC25.lab.local`  
> **Objectif :** Déployer une imprimante réseau partagée (`Printer01`) via un serveur d'impression centralisé et la distribuer automatiquement aux utilisateurs autorisés via GPO avec ciblage par groupe de sécurité AD

---



## Partie A — Installation & Configuration du Print Server

### 1. Installation du rôle Print and Document Services

**Accès :** Server Manager → **Add Roles and Features** → Server Roles

Cocher **Print and Document Services** dans la liste des rôles :

> La description indique que ce rôle permet de centraliser la gestion des serveurs d'impression et des imprimantes réseau.

Les rôles déjà installés sur DC25 sont visibles (AD DS, DHCP, DNS, File and Storage Services).

![Installation Print and Document Services](<../../docs/assets/Windows_server_AD/server impression/1.png>)

---

### 2. Découverte de la console Print Management

**Accès :** Server Manager → Tools → **Print Management** (ou `printmanagement.msc`)

La console affiche les **Ports** disponibles sur `DC25 (local)` :

| Port Name | Port Description | Port Type | Printer Name |
|-----------|-----------------|-----------|--------------|
| `172.1...` | Standard TCP/I... | Write | *(à configurer)* |
| `CO...` | Local Port | Write | — |
| `FILE:` | Local Port | Write | — |
| `LPT1:` | Local Port | Write | — |
| `LPT2:` | Local Port | Write | — |
| `LPT3:` | Local Port | Write | — |
| `POR...` | Local Port | Write | Microsoft Print to PDF |

> Un port TCP/IP Standard existe déjà (`172.1...`) — il a été créé lors d'une étape précédente. Les ports `LPT` et `COM` sont des ports locaux hérités.

![Print Management — Ports](<../../docs/assets/Windows_server_AD/server impression/2.png>)

---

### 3. Ajout du driver HP via Add Printer Driver Wizard

Pour installer un driver d'imprimante tiers (HP), ouvrir l'assistant depuis la console :

**Procédure :** Print Management → **DC25 (local)** → **Drivers** → clic droit → **Add Driver...**

L'assistant **Add Printer Driver Wizard** s'ouvre. Le Server Manager en arrière-plan confirme que **Print Services** est bien actif avec le statut **Manageability OK**.

> L'assistant installe les drivers sur le serveur d'impression. Les clients qui se connectent à l'imprimante partagée reçoivent automatiquement le driver correspondant à leur architecture (x64/x86).

Cliquer **Next** pour continuer.

![Add Printer Driver Wizard — Welcome](<../../docs/assets/Windows_server_AD/server impression/3.png>)

---

### 4. Sélection du fichier .inf — Install From Disk

À l'étape **Printer Driver Selection**, le fabricant **Generic** est sélectionné par défaut. Pour installer le driver HP, cliquer sur **Have Disk...**.

La boîte **Install From Disk** s'ouvre avec un explorateur pointant vers `C:\Windows\System32`. Il faut naviguer vers le dossier contenant le fichier `.inf` du driver HP.

> Le filetype est filtré sur **Setup Information (*.inf)** — c'est le format standard des packages de drivers Windows.

![Install From Disk — Browse vers System32](<../../docs/assets/Windows_server_AD/server impression/4.png>)

---

### 5. Chemin du driver HP Universal Printing PCL 6

Après navigation, le chemin du driver HP est renseigné :

| Paramètre | Valeur |
|-----------|--------|
| **Copy manufacturer's files from** | `B:\upd-pcl6-x64-7.9.0.26347` |

> Le driver **HP Universal Print Driver (UPD) PCL 6** en version **7.9.0.26347** est stocké sur le volume `B:` du serveur. L'UPD HP est un driver universel compatible avec la quasi-totalité des imprimantes HP — idéal pour les environnements d'entreprise.

Cliquer **OK** pour charger le fichier `.inf` et détecter les modèles disponibles.

![Install From Disk — Chemin B:\upd-pcl6-x64](<../../docs/assets/Windows_server_AD/server impression/5.png>)

---

### 6. Driver HP détecté et signé numériquement

Après chargement du fichier `.inf`, la liste des drivers disponibles s'affiche :

| Printers (drivers détectés) |
|-----------------------------|
| HP Universal Printing PCL 6 |
| HP Universal Printing PCL 6 (v7.9.0) |

> Le message **"This driver is digitally signed"** confirme que le driver est signé par HP — garantie d'authenticité et de compatibilité avec Windows Server 2025. Sélectionner **HP Universal Printing PCL 6** et cliquer **Next**.

![Driver HP détecté — Signé numériquement](<../../docs/assets/Windows_server_AD/server impression/6.png>)

---

### 7. Vérification du driver installé dans la liste

Après installation, le driver apparaît dans la liste **Drivers** de Print Management :

| Driver Name | Environment | Driver Version | Driver Isolation | Provider | Server Name | Print Processor |
|-------------|-------------|----------------|-----------------|----------|-------------|----------------|
| **HP Universal Printing PCL 6** | Windows x64 | **61.345.1.26347** | **Shared** | HP | DC25 (local) | hpcpp345 |
| Microsoft enhanced Point and ... | Windows x64 | 10.0.26100.32522 | None | Microsoft | DC25 (local) | winprint |
| Microsoft enhanced Point and ... | Windows NT x86 | 10.0.26100.32522 | None | Microsoft | DC25 (local) | winprint |
| Microsoft IPP Class Driver | Windows x64 | 10.0.26100.32522 | None | Microsoft | DC25 (local) | winprint |
| Microsoft Print To PDF | Windows x64 | 10.0.26100.4484 | None | Microsoft | DC25 (local) | winprint |

> Le driver HP est en **Driver Isolation: Shared** et utilise le processeur d'impression `hpcpp345` propre à HP. La **Driver Date** est le 8/20/2025, confirmant qu'il s'agit d'une version récente compatible Windows Server 2025.

![Drivers — HP Universal Printing PCL 6 installé](<../../docs/assets/Windows_server_AD/server impression/7.png>)

---

### 8. Création d'un port TCP/IP Standard

Pour associer l'imprimante physique à une adresse réseau, créer un nouveau port TCP/IP.

**Procédure :** Print Management → **Ports** → clic droit → **Add Port...**

La boîte **Printer Ports** affiche les types disponibles :

| Type de port | Usage |
|-------------|-------|
| Local Port | Connexion locale (LPT, COM, FILE) |
| **Standard TCP/IP Port** | Connexion réseau via IP ← Sélectionner |

Sélectionner **Standard TCP/IP Port** et cliquer **New Port...**.

![Printer Ports — Standard TCP/IP Port](<../../docs/assets/Windows_server_AD/server impression/8.png>)

---

### 9. Saisie de l'adresse IP de l'imprimante

L'assistant **Add Standard TCP/IP Printer Port Wizard** demande l'adresse IP de l'imprimante.

| Paramètre | Valeur |
|-----------|--------|
| **Printer Name or IP Address** | `172.16.10.10` |
| **Port Name** | `172.16.10.10` *(généré automatiquement)* |

> L'adresse `172.16.10.10` est l'adresse du serveur DC25 lui-même dans ce lab — en production, ce serait l'adresse IP fixe de l'imprimante physique sur le réseau. Cliquer **Next** pour détecter l'équipement.

![Add TCP/IP Port — IP 172.16.10.10](<../../docs/assets/Windows_server_AD/server impression/9.png>)

---

### 10. Device Type — Generic Network Card

Le wizard n'arrive pas à identifier automatiquement l'équipement (normal en environnement lab sans imprimante physique) et affiche :


**Device Type sélectionné :**

| Option | Valeur |
|--------|--------|
| **Standard** | Generic Network Card *(sélectionné)* |
| Custom | — |

> En environnement de production, le wizard détecte automatiquement le type SNMP de l'imprimante. En lab, choisir **Generic Network Card** et continuer — le port sera créé et fonctionnel pour la configuration logique.

Cliquer **Next** puis **Finish** pour créer le port.

![Additional Port Info — Generic Network Card](<../../docs/assets/Windows_server_AD/server impression/10.png>)

---

## Partie B — Création et partage de l'imprimante

### 11. Recherche de l'imprimante dans l'annuaire AD

Dans l'assistant **Network Printer Installation Wizard**, une recherche dans l'annuaire AD est effectuée pour trouver l'imprimante publiée.

**Résultat de la recherche :**

| Name | Type | Description |
|------|------|-------------|
| **DC25-Printer01** | Printer | printer |

> **1 item(s) found** — L'imprimante `DC25-Printer01` est déjà publiée dans Active Directory. Elle peut être sélectionnée directement depuis l'annuaire.

![Find Custom Search — DC25-Printer01 trouvée](<../../docs/assets/Windows_server_AD/server impression/11.png>)

---

### 12. Sélection du port TCP/IP existant

Dans le **Network Printer Installation Wizard**, choisir la méthode d'installation :

| Option | Sélectionnée |
|--------|-------------|
| Search the network for printers | ☐ |
| Add an IPP, TCP/IP, or Web Services Printer by IP | ☐ |
| **Add a new printer using an existing port** | ✅ |
| Create a new port and add a new printer | ☐ |

**Port sélectionné dans la liste déroulante :**

```
172.16.10.10 (Standard TCP/IP Port)   ← Sélectionné
```

> Le port TCP/IP créé à l'étape précédente (`172.16.10.10`) est maintenant disponible dans la liste. Cette approche réutilise le port existant sans en créer un nouveau.

![Network Printer Wizard — Port TCP/IP existant](<../../docs/assets/Windows_server_AD/server impression/12.png>)

---

### 13. Association du driver HP existant

À l'étape **Printer Driver**, le wizard propose d'utiliser le driver déjà installé sur le serveur :

| Option | Sélectionnée |
|--------|-------------|
| Use the printer driver that the wizard selected | ☐ *(Compatible driver cannot be found)* |
| **Use an existing printer driver on the computer** | ✅ |
| Install a new driver | ☐ |

**Driver sélectionné :** `HP Universal Printing PCL 6`

> Le driver HP installé précédemment est automatiquement proposé. Cela évite une installation redondante et garantit la cohérence de version sur le serveur.

![Printer Driver — HP Universal Printing PCL 6](<../../docs/assets/Windows_server_AD/server impression/13.png>)

---

### 14. Nommage et partage de l'imprimante

L'étape **Printer Name and Sharing Settings** configure l'identité de l'imprimante sur le réseau :

| Paramètre | Valeur |
|-----------|--------|
| **Printer Name** | `Printer01` |
| **Share this printer** | ✅ |
| **Share Name** | `Printer01` |
| **Location** | `1st floor` |
| **Comment** | `printer` |

> Le champ **Location** (`1st floor`) permet aux utilisateurs de localiser physiquement l'imprimante lors d'une recherche dans l'annuaire AD. Le nom de partage `Printer01` sera utilisé dans le chemin UNC `\\DC25\Printer01`.

Cliquer **Next** puis **Finish** pour créer l'imprimante.

![Printer Name & Sharing — Printer01, 1st floor](<../../docs/assets/Windows_server_AD/server impression/14.png>)

---

### 15. Vue d'ensemble des imprimantes dans Print Management

La console **Print Management → Printers** liste désormais 2 imprimantes sur `DC25 (local)` :

| Printer Name | Queue Status | Jobs In Queue | Server Name | Driver Name | Driver Version | Driver Type |
|--------------|-------------|---------------|-------------|-------------|----------------|-------------|
| Microsoft Print to PDF | Ready | 0 | DC25 (local) | Microsoft Print To PDF | 10.0.26100.4484 | Type 4 - User Mode |
| **Printer01** | **Ready** | **0** | DC25 (local) | HP Universal Printing PCL 6 | 10.0.26100.4484 | Type 4 - User Mode |

> `Printer01` est en statut **Ready** avec 0 travaux en attente. Le type **4 - User Mode** est le modèle de driver moderne recommandé pour Windows Server 2025.

![Print Management Printers — Printer01 Ready](<../../docs/assets/Windows_server_AD/server impression/15.png>)

---

### 16. Propriétés de partage — Printer01

Dans les propriétés de `Printer01`, onglet **Sharing** :

| Paramètre | Valeur |
|-----------|--------|
| **Share this printer** | ✅ |
| **Share name** | `Printer01` |
| **Render print jobs on client computers** | ✅ |
| **List in the directory** | ✅ |

> L'option **"List in the directory"** publie l'imprimante dans Active Directory — elle sera trouvable via la recherche AD par les utilisateurs du domaine. **"Render print jobs on client computers"** délègue le rendu au poste client, réduisant la charge du serveur d'impression.

![Printer01 Properties — Sharing](<../../docs/assets/Windows_server_AD/server impression/16.png>)

---

## Partie C — Déploiement via GPO avec ciblage AD

### 17. Création de l'OU Printer dans PEAKY-BLINDERS

Pour organiser les objets liés à l'impression, une OU dédiée est créée dans `PEAKY-BLINDERS`.

**Procédure :** ADUC → clic droit sur `PEAKY-BLINDERS` → **New** → **Organizational Unit**

| Paramètre | Valeur |
|-----------|--------|
| **Name** | `Printer` |
| **Protect from accidental deletion** | ✅ |

> Cette OU accueillera le groupe de sécurité `GP-PRINTER01` qui contrôlera l'accès à l'imprimante via le ciblage GPO.

![Création OU Printer dans PEAKY-BLINDERS](<../../docs/assets/Windows_server_AD/server impression/17.png>)

---

### 18. Création du groupe GP-PRINTER01

Dans l'OU `Printer`, créer un groupe de sécurité pour contrôler l'accès à `Printer01`.

**Accès :** Clic droit sur l'OU `Printer` → **New** → **Group**

| Paramètre | Valeur |
|-----------|--------|
| **Group name** | `GP-PRINTER01` |
| **Group scope** | Global |
| **Group type** | Security |
| **Create in** | `lab.local/PEAKY-BLINDERS/Printer` |

> Ce groupe sera utilisé comme **critère de ciblage (Item-level targeting)** dans la GPO : seuls les utilisateurs membres de `GP-PRINTER01` recevront automatiquement l'imprimante `Printer01` à leur connexion.

![Création groupe GP-PRINTER01](<../../docs/assets/Windows_server_AD/server impression/18.png>)

---

### 19. Création de la GPO PRINTER

Une deuxième GPO est créée et liée à l'OU `PEAKY-BLINDERS` pour le déploiement de l'imprimante.

**Accès :** Group Policy Management → clic droit sur `PEAKY-BLINDERS` → **Create a GPO in this domain, and Link it here...**

La GPO `GARRISON` (Drive Maps) est déjà liée (Link Order 1). La nouvelle GPO sera nommée `PRINTER`.

> Deux GPOs distinctes sont utilisées par souci de clarté et de maintenabilité : `GARRISON` pour les lecteurs réseau, `PRINTER` pour l'imprimante. Cela permet de les activer/désactiver indépendamment.

![GPM — Création GPO PRINTER](<../../docs/assets/Windows_server_AD/server impression/19.png>)

---

### 20. Configuration GPO — Shared Printer

Dans l'éditeur de la GPO `PRINTER` :

**Chemin :** User Configuration → Preferences → Control Panel Settings → **Printers** → clic droit → **New** → **Shared Printer**

> Le type **Shared Printer** permet de déployer une imprimante déjà partagée sur un serveur, identifiée par son chemin UNC. C'est la méthode recommandée pour déployer des imprimantes via GPO dans un domaine Active Directory.

![GPO PRINTER — New Shared Printer](<../../docs/assets/Windows_server_AD/server impression/20.png>)

---

### 21. Item-level targeting — Common tab

Dans les propriétés **New Shared Printer**, onglet **Common** :

| Option | État |
|--------|------|
| Stop processing items if error occurs | ☐ |
| Run in logged-on user's security context | ☐ |
| Remove this item when it is no longer applied | ☐ |
| Apply once and do not reapply | ☐ |
| **Item-level targeting** | ✅ |

Cliquer sur **Targeting...** pour configurer la règle de ciblage.

> L'**Item-level targeting** est la fonctionnalité clé qui permet de n'appliquer cette préférence GPO qu'aux utilisateurs répondant à des critères précis (groupe AD, OS, site, etc.) — sans avoir besoin de créer des OU séparées ou de filtrer la GPO entière.

![New Shared Printer — Common, Item-level targeting](<../../docs/assets/Windows_server_AD/server impression/21.png>)

---

### 22. Targeting Editor — Règle de groupe de sécurité

Le **Targeting Editor** s'ouvre. Ajouter un critère via **New Item** :

**Critère sélectionné :** `the user is a member of the security group`

| Option | Sélectionnée |
|--------|-------------|
| Primary group | ☐ |
| **User in group** | ✅ |
| Computer in group | ☐ |

> Ce critère vérifie l'appartenance de l'utilisateur connecté à un groupe AD spécifique. L'option **"User in group"** évalue le contexte utilisateur (et non l'ordinateur), ce qui est cohérent avec une préférence dans **User Configuration**.

![Targeting Editor — Security Group, User in group](<../../docs/assets/Windows_server_AD/server impression/22.png>)

---

### 23. Targeting Editor — Groupe LAB\GP-PRINTER01 résolu

Le groupe `GP-PRINTER01` est résolu dans le Targeting Editor :

| Paramètre | Valeur |
|-----------|--------|
| **Group** | `LAB\GP-PRINTER01` |
| **SID** | `S-1-5-21-1530077734-2617936954-3773108608-1113` |
| **Mode** | User in group |

**Règle finale affichée :**
> *"the user is a member of the security group LAB\GP-PRINTER01"*

> Le SID est résolu automatiquement lors de la saisie du nom du groupe — il garantit que la règle reste valide même si le groupe est renommé. Cliquer **OK** pour valider.

![Targeting Editor — GP-PRINTER01 résolu avec SID](<../../docs/assets/Windows_server_AD/server impression/23.png>)

---

### 24. Attribution de GP-PRINTER01 à THOMAS TS. SHELBY

Pour que `TSHELBY` reçoive l'imprimante automatiquement, l'ajouter au groupe `GP-PRINTER01`.

**Procédure :** ADUC → `THOMAS TS. SHELBY` → Properties → onglet **Member Of** → **Add**

| Élément | Valeur |
|---------|--------|
| **Groupes déjà membres** | Domain Users, DR-GP |
| **Groupe ajouté** | `GP-PRINTER01` |
| **Location** | `lab.local` |

> TSHELBY est maintenant membre de `DR-GP` (accès au dossier Direction) ET de `GP-PRINTER01` (réception automatique de Printer01 via GPO). L'OU `Printer` est bien visible dans l'arborescence ADUC.

![ADUC — TSHELBY ajouté à GP-PRINTER01](<../../docs/assets/Windows_server_AD/server impression/24.png>)

---

## Partie D — Validation côté client

### 25. Client Windows 10 — Printer01 on DC25 visible

Sur le poste client Windows 10 connecté avec le compte `TSHELBY` :

**Accès :** Settings → Devices → **Printers & scanners**

La liste des imprimantes affiche :

- Fax
- Microsoft Print to PDF
- Microsoft XPS Document Writer
- OneNote for Windows 10
- **Printer01 on DC25** ← Ajoutée automatiquement par GPO ✅

> ✅ L'imprimante `Printer01 on DC25` a été déployée automatiquement sur le poste client grâce à la GPO `PRINTER` avec le ciblage `GP-PRINTER01`. TSHELBY, membre du groupe, reçoit l'imprimante sans aucune action manuelle.

![Client Windows 10 — Printer01 on DC25](<../../docs/assets/Windows_server_AD/server impression/25.png>)

---

### 26. Client — Gestion de Printer01 on DC25

En cliquant sur `Printer01 on DC25` dans les paramètres, la page de gestion s'affiche :

| Élément | Valeur |
|---------|--------|
| **Printer status** | 1 document(s) in queue |
| **Open print queue** | *(bouton disponible)* |
| Print a test page | *(lien disponible)* |
| Run the troubleshooter | *(lien disponible)* |
| Printer properties | *(lien disponible)* |

> L'utilisateur peut imprimer une page de test, consulter la file d'attente et accéder aux propriétés directement depuis Windows Settings — sans avoir besoin d'accéder à la console Print Management du serveur.

![Client — Printer01 on DC25 — 1 document in queue](<../../docs/assets/Windows_server_AD/server impression/26.png>)

---

### 27. Validation serveur — Test Page en file d'attente

De retour sur le serveur, la console **Print Management → Printers** confirme la réception du travail d'impression :

**État de Printer01 :**

| Printer Name | Queue Status | Jobs In Queue | Driver Name |
|--------------|-------------|---------------|-------------|
| **Printer01** | **Error** | **1** | HP Universal Printing PCL 6 |

**File d'attente Printer01 :**

| Document Name | Status | Owner | Pages | Size | Submitted |
|---------------|--------|-------|-------|------|-----------|
| Test Page | **Error - Prin...** | **TSHELBY** | 1 | 143 KB | 12:29:12 AM 4/2/20 |

> Le statut **Error** est attendu en environnement lab — il n'y a pas d'imprimante physique à l'adresse `172.16.10.10`. Le travail `Test Page` soumis par `TSHELBY` (143 KB, 1 page) confirme cependant que :
> - La GPO a bien déployé l'imprimante sur le poste client
> - L'utilisateur TSHELBY a bien pu soumettre un travail d'impression
> - Le serveur d'impression DC25 reçoit et gère les travaux
>
> En production avec une vraie imprimante, le document s'imprimerait normalement.

![Print Management — Test Page de TSHELBY en queue](<../../docs/assets/Windows_server_AD/server impression/27.png>)
---

## Remarques

- Le statut **Error** sur `Printer01` est normal en lab sans imprimante physique — il confirme néanmoins le bon fonctionnement de la chaîne serveur d'impression → client → GPO.
- Le driver **HP Universal Print Driver (UPD) PCL 6** est un choix professionnel adapté à la majorité des imprimantes HP en entreprise. Son architecture universelle évite la gestion de drivers spécifiques par modèle.
- L'**Item-level targeting** est préférable au filtrage de sécurité de la GPO pour les préférences d'imprimantes : il permet un ciblage granulaire sans multiplier les GPOs.
- En production, il est recommandé d'utiliser des **adresses IP fixes** pour les imprimantes réseau et de les déclarer en DNS pour faciliter la résolution.


