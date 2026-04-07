#!/bin/bash
# --------------------------------------------------------------------
# Zabbix 7.0 (MySQL/MariaDB) - Ubuntu 22.04 / 24.04
# Fully non-interactive (no prompts). MariaDB root uses unix_socket.
# DB user password is FIXED to: Password*   (lab only)
# Idempotent: safe re-runs
# --------------------------------------------------------------------

set -euo pipefail

# ---------- Helpers ----------
log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }
trap 'err "Script failed at line $LINENO"; exit 1' ERR

# Require root
[[ $EUID -eq 0 ]] || die "Please run as root (sudo -i)."

# ---------- Variables ----------
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="Password*"                 # <-- fixed default password
SECRETS_FILE="/root/.zabbix-db.cnf"
ZBX_REPO_BASE="https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release"

# Detect Ubuntu major (22 or 24)
UBUNTU_MAJ="$(lsb_release -rs | cut -d. -f1)"
REPO_DEB="zabbix-release_7.0-1+ubuntu${UBUNTU_MAJ}.04_all.deb"
REPO_URL="${ZBX_REPO_BASE}/${REPO_DEB}"

# ---------- Functions ----------
wait_for_dpkg() {
  log "Checking apt/dpkg locks…"
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    warn "dpkg is locked by another process. Waiting 10s…"
    sleep 10
  done
}

ensure_pkg() {
  local pkgs=("$@")
  wait_for_dpkg
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
}

set_kv() {
  # ensure key=value in file (replace if exists, else append)
  # usage: set_kv FILE KEY VALUE
  local file="$1" key="$2" value="$3"
  if grep -qE "^[# ]*${key}=" "$file"; then
    sed -i "s|^[# ]*${key}=.*|${key}=${value}|g" "$file"
  else
    echo "${key}=${value}" >>"$file"
  fi
}

save_secret() {
  umask 077
  cat > "$SECRETS_FILE" <<EOF
# Zabbix DB credentials (installed by script)
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
EOF
  chmod 600 "$SECRETS_FILE"
}

# ---------- System prep ----------
log "Updating system packages…"
wait_for_dpkg
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installing prerequisites…"
ensure_pkg wget curl gnupg lsb-release locales openssl \
           mariadb-server mariadb-client

# ---------- MariaDB ----------
log "Starting & enabling MariaDB…"
systemctl enable --now mariadb

log "Securing MariaDB minimally (no root password; unix_socket auth)…"
mysql -e "DELETE FROM mysql.user WHERE User='';" || true
mysql -e "DROP DATABASE IF EXISTS test;" || true
mysql -e "FLUSH PRIVILEGES;"

log "Creating Zabbix database & user (if not exists)…"
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# ---------- Save secrets (root-only) ----------
log "Saving DB credentials to ${SECRETS_FILE} (chmod 600)…"
save_secret

# ---------- Zabbix repo & packages ----------
log "Adding Zabbix repository for Ubuntu ${UBUNTU_MAJ}.04…"
tmpdeb="/tmp/${REPO_DEB}"
wget -q "${REPO_URL}" -O "${tmpdeb}" || die "Failed to download ${REPO_URL}"
dpkg -i "${tmpdeb}"
apt-get update -y

log "Installing Zabbix server, frontend, SQL scripts, and agent…"
ensure_pkg zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# ---------- Import initial schema (idempotent) ----------
log "Checking if Zabbix schema is present…"
if ! mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "SHOW TABLES LIKE 'users';" | grep -q users; then
  warn "Schema not found; importing initial schema (this may take a moment)…"
  zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz \
    | mysql -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"
else
  log "Schema already present; skipping import."
fi

# ---------- Configure Zabbix server ----------
ZBX_CONF="/etc/zabbix/zabbix_server.conf"
log "Configuring Zabbix server at ${ZBX_CONF}…"
set_kv "${ZBX_CONF}" "DBName"     "${DB_NAME}"
set_kv "${ZBX_CONF}" "DBUser"     "${DB_USER}"
set_kv "${ZBX_CONF}" "DBPassword" "${DB_PASS}"

# ---------- Locales for multilingual UI (optional) ----------
log "Generating common locales for Zabbix UI…"
locale-gen --purge
locale-gen en_US.UTF-8 fr_FR.UTF-8 de_DE.UTF-8 es_ES.UTF-8 it_IT.UTF-8 pt_BR.UTF-8 ru_RU.UTF-8 ja_JP.UTF-8 zh_CN.UTF-8 ar_SA.UTF-8
update-locale

# ---------- (Optional) UFW rules ----------
if command -v ufw >/dev/null 2>&1; then
  if ufw status | grep -q "Status: active"; then
    log "UFW detected: allowing HTTP(80) and Zabbix server port(10051)…"
    ufw allow 80/tcp    >/dev/null || true
    ufw allow 10051/tcp >/dev/null || true
  fi
fi

# ---------- Enable & start services ----------
log "Enabling and restarting Zabbix services…"
systemctl enable zabbix-server zabbix-agent apache2
systemctl restart zabbix-server zabbix-agent apache2

sleep 4
if systemctl is-active --quiet zabbix-server; then
  IP="$(hostname -I | awk '{print $1}')"
  log "✅ Zabbix server is running."
  echo
  echo "🌍 Frontend:   http://${IP}/zabbix"
  echo "👉 Login:      Admin / zabbix"
  echo "🗄️ Database:   ${DB_NAME} (user: ${DB_USER})"
  echo "🔐 Password:   stored at ${SECRETS_FILE}"
  echo "🛡️ Note:       MariaDB root uses unix_socket (no password prompt)."
  echo "⚠️  WARNING: fixed DB password 'Password*' is insecure for production."
  echo
else
  die "Zabbix server not active. Check logs: /var/log/zabbix/zabbix_server.log"
fi
