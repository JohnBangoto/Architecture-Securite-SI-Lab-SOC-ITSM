# 🔒 Durcissement du VPS (soc-server)

> Documentation des étapes de sécurisation du serveur VPS Ubuntu 22.04 LTS hébergeant la stack de supervision (Zabbix, Wazuh, GLPI).

---

## 1. Audit initial — SSH & Pare-feu

Avant toute modification, on réalise un audit de l'état initial du serveur : vérification de la configuration SSH et des règles UFW.

![Audit initial SSH et UFW](../../docs/assets/Durcissement/1.png)

**Constats :**
- `PermitRootLogin yes` → la connexion SSH en root est **activée** ⚠️
- Le port `3389` (RDP) est ouvert inutilement ⚠️
- `Fail2Ban` n'est pas installé ⚠️
- Les ports nécessaires sont ouverts : `22`, `80/tcp`, `443/tcp`, `1514/tcp`, `1515/tcp`, `10051/tcp`

---

## 2. Création d'un utilisateur non-root & Sécurisation SSH

Création d'un utilisateur dédié `socadmin` avec droits sudo, désactivation du login root SSH, suppression du port RDP et limitation des tentatives SSH.

![Création utilisateur et sécurisation SSH](../../docs/assets/Durcissement/2.png)

```bash
# Créer l'utilisateur socadmin
adduser socadmin
usermod -aG sudo socadmin

# Désactiver le login root via SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Supprimer la règle RDP inutile
ufw delete allow 3389
ufw delete allow 3389/tcp

# Limiter les tentatives SSH (anti brute-force)
ufw limit 22/tcp
```

**Résultat :** Le port RDP est fermé, le root SSH est désactivé et le port 22 est en mode `LIMIT`.

---

## 3. Installation et configuration de Fail2Ban

Installation de Fail2Ban et configuration avancée pour protéger le serveur contre les attaques par force brute sur SSH, Apache et l'API GLPI.

### 3.1 Installation

![Installation Fail2Ban](../../docs/assets/Durcissement/3.png)

```bash
apt install fail2ban -y
```

**Paquets installés :**
- `fail2ban` (0.11.2-6)
- `python3-pyinotify` (0.9.6-1.3)
- `whois` (5.5.13)

---

### 3.2 Configuration avancée — jail.local

> 💡 Le script complet est disponible dans le dossier `scripts/fail2ban/jail.local` du projet.

**Commande de déploiement :**

```bash
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ignorer ces IPs (réseau local + VPN)
ignoreip = 127.0.0.1/8 ::1

# Ban incrémental pour récidivistes
bantime.increment = true
bantime.multiplier = 24
bantime.maxtime = -1

# Paramètres par défaut
bantime  = 86400
findtime = 600
maxretry = 3
backend  = auto

# ── SSH ───────────────────────────────────────────────────
[sshd]
enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 86400

# ── APACHE ────────────────────────────────────────────────
[apache-auth]
enabled  = true
port     = http,https
filter   = apache-auth
logpath  = /var/log/apache2/error.log
maxretry = 3

[apache-badbots]
enabled  = true
port     = http,https
filter   = apache-badbots
logpath  = /var/log/apache2/access.log
maxretry = 2
bantime  = 172800

[apache-noscript]
enabled  = true
port     = http,https
filter   = apache-noscript
logpath  = /var/log/apache2/access.log
maxretry = 3

[apache-overflows]
enabled  = true
port     = http,https
filter   = apache-overflows
logpath  = /var/log/apache2/access.log
maxretry = 2

[apache-scan]
enabled  = true
port     = http,https
filter   = apache-scan
logpath  = /var/log/apache2/access.log
maxretry = 5
bantime  = 172800

# ── GLPI ──────────────────────────────────────────────────
[glpi]
enabled  = true
port     = http,https
filter   = glpi
logpath  = /var/log/apache2/access.log
maxretry = 5
bantime  = 86400
EOF
```

![Script jail.local complet](../../docs/assets/Durcissement/fail2ban_script.png)

**Filtres personnalisés créés :**

```bash
# Filtre scan .env (attaques de reconnaissance)
cat > /etc/fail2ban/filter.d/apache-scan.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "(GET|POST|HEAD).*(\.env|\.git|\.config|wp-admin|phpMyAdmin).*" (404|400|403) .*$
ignoreregex =
EOF

# Filtre API GLPI
cat > /etc/fail2ban/filter.d/glpi.conf << 'EOF'
[Definition]
failregex = ^<HOST> .* "POST /apirest\.php.*" (401|403) .*$
ignoreregex =
EOF
```

**Paramètres clés :**

| Paramètre | Valeur | Description |
|---|---|---|
| `bantime` | `86400` | Ban de 24h par défaut |
| `bantime.increment` | `true` | Ban croissant pour récidivistes |
| `bantime.multiplier` | `24` | Multiplicateur x24 à chaque récidive |
| `bantime.maxtime` | `-1` | Ban permanent pour les récidivistes |
| `maxretry` | `3` | 3 tentatives avant ban |
| `findtime` | `600` | Fenêtre de détection de 10 min |

**Jails actifs et leur protection :**

| Jail | Protection | Bantime |
|---|---|---|
| `sshd` | Brute force SSH | 24h + incrémental |
| `apache-auth` | Auth Apache | 24h |
| `apache-badbots` | Bots malveillants | 48h |
| `apache-noscript` | Injection scripts | 24h |
| `apache-overflows` | Buffer overflow | 24h |
| `apache-scan` | Scan `.env` / `.git` | 48h |
| `glpi` | API GLPI brute force | 24h |

---

### 3.3 Démarrage et vérification

```bash
systemctl restart fail2ban
systemctl enable fail2ban

# Vérifier tous les jails actifs
fail2ban-client status

# Vérifier chaque jail
fail2ban-client status sshd
fail2ban-client status apache-auth
fail2ban-client status apache-badbots
fail2ban-client status apache-scan
fail2ban-client status glpi
```

![Vérification jails Fail2Ban](../../docs/assets/VPS/fail2ban_verification.png)

**Résultat :** Les 7 jails sont **actifs et opérationnels** ✅

> ⚠️ L'erreur `Failed to access socket path` visible en début de sortie est sans importance — elle indique simplement que Fail2Ban n'avait pas encore fini de démarrer au moment de la première requête. Tous les jails sont correctement chargés ensuite.

---

## 4. Mises à jour automatiques & Vérification UFW

Installation des mises à jour de sécurité automatiques et vérification de l'état final du pare-feu.

![Unattended upgrades et UFW final](../../docs/assets/VPS/fail2ban_verification.png)

```bash
apt install unattended-upgrades -y
dpkg-reconfigure -plow unattended-upgrades
```

**État UFW après durcissement :**

| Port | Action | Remarque |
|------|---------|----------|
| 22 | ALLOW IN | SSH |
| 22/tcp | **LIMIT IN** | Anti brute-force ✅ |
| 80/tcp | ALLOW IN | HTTP |
| 443/tcp | ALLOW IN | HTTPS |
| 1514/tcp | ALLOW IN | Wazuh |
| 1515/tcp | ALLOW IN | Wazuh |
| 10051/tcp | ALLOW IN | Zabbix |

> Le port `3389` (RDP) a bien été supprimé ✅

---

## 5. Démarrage et activation de Fail2Ban

Démarrage du service Fail2Ban, activation au démarrage et vérification du statut.

![Fail2Ban actif](../../docs/assets/Durcissement/5.png)

```bash
systemctl start fail2ban
systemctl enable fail2ban
systemctl status fail2ban | head -3
```

**Résultat :** Fail2Ban est **actif et en cours d'exécution** depuis le `2026-04-24 01:41:17 UTC` ✅

---

## 6. Génération de clé SSH côté client

Depuis le poste Windows (PowerShell), génération d'une paire de clés SSH ED25519 pour une authentification sans mot de passe.

![Génération clé SSH](../../docs/assets/Durcissement/6.png)

```powershell
ssh-keygen -t ed25519 -C "socadmin@monlab"
```

**Résultat :**
- Clé privée : `C:\Users\DELL\.ssh\id_ed25519`
- Clé publique : `C:\Users\DELL\.ssh\id_ed25519.pub`
- Algorithme : **ED25519** (plus sécurisé que RSA) ✅

---

## 7. Déploiement de la clé publique & Connexion SSH par clé

Copie de la clé publique sur le serveur et première connexion SSH par clé sans mot de passe.

![Déploiement clé et connexion SSH](../../docs/assets/Durcissement/7.png)

```powershell
# Copier la clé publique sur le serveur
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh socadmin@194.146.38.216 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Se connecter via clé SSH
ssh socadmin@194.146.38.216
```

**Résultat :** Connexion réussie en tant que `socadmin` sur **Ubuntu 22.04.5 LTS** sans mot de passe ✅

---

## 8. Désactivation de l'authentification par mot de passe

Dernière étape critique : désactivation totale de l'authentification par mot de passe SSH pour forcer l'usage des clés.

![Désactivation PasswordAuthentication](../../docs/assets/Durcissement/8.png)

```bash
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Vérification
grep "PasswordAuthentication" /etc/ssh/sshd_config
```

**Résultat :** `PasswordAuthentication no` ✅ — Seules les clés SSH sont acceptées désormais.

---

## 9. Vérification — Blocage de la connexion root

Test final : tentative de connexion SSH en root → accès refusé, confirmant que le durcissement est effectif.

![Connexion root refusée](../../docs/assets/Durcissement/9.png)

```bash
ssh root@194.146.38.216
# → Permission denied, please try again.
```

**Résultat :** La connexion root est bien **bloquée** ✅

---