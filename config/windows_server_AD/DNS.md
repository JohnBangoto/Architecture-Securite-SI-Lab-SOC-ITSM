# 🌐 Configuration du Service DNS — Windows Server 2025


---

## 1. Configuration des redirecteurs (Forwarders)

Les **redirecteurs DNS** permettent au serveur de transmettre les requêtes qu'il ne peut pas résoudre localement vers des serveurs DNS externes (Internet).

**Accès :** DNS Manager → clic droit sur **DC25** → **Properties** → onglet **Forwarders** → **Edit**

| IP Address | Server FQDN | Statut |
|------------|-------------|--------|
| `8.8.8.8` | `dns.google` | ✅ OK |
| `1.1.1.1` | `one.one.one.one` | ✅ OK |

**Paramètre supplémentaire :**
- **Timeout** : `3` secondes avant qu'une requête forwardée soit considérée comme échouée

> Les deux serveurs sont validés automatiquement par le gestionnaire DNS dès leur ajout. L'utilisation combinée de Google DNS et Cloudflare assure une redondance pour la résolution externe.

![Configuration des redirecteurs DNS](../../docs/assets/Windows_server_AD/DNS/5.png)

---

## 2. Création de la zone de recherche inversée

La **zone de recherche inversée** (Reverse Lookup Zone) permet de résoudre une adresse IP en nom d'hôte — opération indispensable pour les outils de diagnostic et certains services réseau.

**Accès :** DNS Manager → **Reverse Lookup Zones** → clic droit → **New Zone**

La zone créée correspond au sous-réseau `172.16.10.0/24`, ce qui génère automatiquement la zone `10.16.172.in-addr.arpa`.

**Enregistrements initiaux présents après création :**

| Name | Type | Data | Timestamp |
|------|------|------|-----------|
| (same as parent folder) | Start of Authority (SOA) | `[1], dc25.lab.local., hostm...` | static |
| (same as parent folder) | Name Server (NS) | `dc25.lab.local.` | static |

> À ce stade, aucun enregistrement PTR n'est encore présent. Il sera créé à l'étape suivante.

![Zone inversée 10.16.172.in-addr.arpa — création initiale](../../docs/assets/Windows_server_AD/DNS/1.png)

---

## 3. Mise à jour de l'enregistrement Host (A) avec PTR

Pour lier l'enregistrement **A** (résolution directe) à un enregistrement **PTR** (résolution inverse), il faut modifier les propriétés de l'hôte `dc25` dans la zone de recherche directe.

**Accès :** DNS Manager → **Forward Lookup Zones** → `lab.local` → double-clic sur `dc25`

| Champ | Valeur |
|-------|--------|
| **Host** | `dc25` |
| **FQDN** | `dc25.lab.local` |
| **IP address** | `172.16.10.10` |
| **Update associated PTR record** | ✅ Coché |

> Cocher **"Update associated pointer (PTR) record"** provoque la création automatique de l'enregistrement PTR correspondant dans la zone `10.16.172.in-addr.arpa`. Cliquer sur **Apply** puis **OK** pour valider.

![Propriétés dc25 — Host A avec mise à jour PTR](../../docs/assets/Windows_server_AD/DNS/2.png)

---

## 4. Vérification de l'enregistrement PTR dans la zone inversée

Après la mise à jour de l'enregistrement A, retourner dans la zone inversée pour confirmer la création du PTR.

**Accès :** DNS Manager → **Reverse Lookup Zones** → `10.16.172.in-addr.arpa`

| Name | Type | Data | Timestamp |
|------|------|------|-----------|
| (same as parent folder) | Start of Authority (SOA) | `[2], dc25.lab.local., hostm...` | static |
| (same as parent folder) | Name Server (NS) | `dc25.lab.local.` | static |
| `172.16.10.10` | **Pointer (PTR)** | `dc25.lab.local.` | static |

> L'enregistrement **PTR** est désormais présent et pointe correctement `172.16.10.10` → `dc25.lab.local`. La résolution inverse est opérationnelle.

![Zone inversée avec enregistrement PTR créé](../../docs/assets/Windows_server_AD/DNS/3.png)

---

## 5. Validation technique via nslookup

La résolution DNS est testée en ligne de commande pour confirmer que la configuration est fonctionnelle de bout en bout.

**Commande exécutée :**

```cmd
nslookup 172.16.10.10 172.16.10.10
```

> Cette syntaxe interroge directement le serveur `172.16.10.10` (DC25) pour résoudre l'adresse `172.16.10.10` en nom d'hôte.

**Résultat obtenu :**

```
Server:   dc25.lab.local
Address:  172.16.10.10

Name:     dc25.lab.local
Address:  172.16.10.10
```

✅ Le serveur DNS répond correctement : l'adresse `172.16.10.10` est bien résolue en `dc25.lab.local`, confirmant que les zones directe et inverse sont correctement configurées.

![Test nslookup](../../docs/assets/Windows_server_AD/DNS/4.png)


## Remarques
- L'option **"Update associated PTR record"** doit toujours être cochée lors de la création ou modification d'enregistrements A pour maintenir la cohérence entre zones directe et inversée.
- Le timeout des forwarders est réglé à **3 secondes**, valeur par défaut recommandée pour un environnement avec connexion Internet stable.

---
