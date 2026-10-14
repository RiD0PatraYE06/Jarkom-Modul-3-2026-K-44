#Konfig master di yaga

cat > /root/soal-13.sh <<'EOF'
#!/bin/sh
set -eu

DB="db_shibuya_k44"
CONF="/etc/mysql/mariadb.conf.d/60-soal-13.cnf"
BACKUP="/root/soal-13"

# Pastikan yaga memiliki alamat pada Network 4.
MASTER_IP=$(ip -4 -o addr show scope global |
    awk '$4 ~ /^192\.233\.4\./ {
        a=$4
        sub(/\/.*/, "", a)
        print a
        exit
    }')

if [ -z "$MASTER_IP" ]; then
    echo "ERROR: IP yaga pada 192.233.4.0/24 tidak ditemukan."
    exit 1
fi

# Instal paket hanya jika MariaDB belum terpasang.
if ! command -v mariadbd >/dev/null 2>&1; then
    apt-get install -y mariadb-server mariadb-client
fi

mkdir -p "$BACKUP"

# Simpan konfigurasi lama jika ada.
if [ -f "$CONF" ] && [ ! -f "$BACKUP/60-soal-13.cnf.before" ]; then
    cp -a "$CONF" "$BACKUP/60-soal-13.cnf.before"
fi

# Simpan konfigurasi Master di /root.
cat > "$BACKUP/60-soal-13-master.cnf" <<'CNF'
[mariadb]
server-id=44
log-bin=mariadb-bin
binlog-format=ROW
bind-address=0.0.0.0
CNF

# Pasang konfigurasi aktif.
install -m 0644 "$BACKUP/60-soal-13-master.cnf" "$CONF"

echo "=== Restart MariaDB Master ==="
service mariadb restart

echo "=== Buat database dan tabel ==="
mariadb -uroot <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_k44;

USE db_shibuya_k44;

CREATE TABLE IF NOT EXISTS request_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR(10) DEFAULT NULL,
    path VARCHAR(255) DEFAULT NULL,
    client_ip VARCHAR(45) DEFAULT NULL,
    status_code SMALLINT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE USER IF NOT EXISTS
    'repl_k44'@'192.233.4.%'
    IDENTIFIED BY 'ReplK44_2026!';

GRANT REPLICATION SLAVE ON *.*
    TO 'repl_k44'@'192.233.4.%';

CREATE USER IF NOT EXISTS
    'app_k44'@'192.233.4.%'
    IDENTIFIED BY 'AppK44_2026!';

GRANT SELECT, INSERT, UPDATE, DELETE
    ON db_shibuya_k44.*
    TO 'app_k44'@'192.233.4.%';

FLUSH PRIVILEGES;
SQL

echo "=== Verifikasi binary logging ==="
mariadb -uroot -e \
    "SHOW VARIABLES WHERE Variable_name IN ('server_id','log_bin','binlog_format');"

echo "=== IP Master ==="
echo "$MASTER_IP"

echo "=== File dan posisi binary log Master ==="
mariadb -uroot -e "SHOW MASTER STATUS\G"

echo "Skrip: /root/soal-13.sh"
echo "Konfigurasi: $BACKUP/60-soal-13-master.cnf"
echo "Backup konfigurasi sebelumnya: $BACKUP"
EOF

chmod +x /root/soal-13.sh
/root/soal-13.sh

#Knfig slave di inumaki

cat > /root/soal-13.sh <<'EOF'
#!/bin/sh
set -eu

BACKUP="/root/soal-13"
CONF="/etc/mysql/mariadb.conf.d/60-soal-13.cnf"

# Minta alamat dan posisi binary log dari yaga.
printf "Masukkan IP Master yaga: "
IFS= read -r MASTER_IP

printf "Masukkan File dari SHOW MASTER STATUS: "
IFS= read -r MASTER_LOG_FILE

printf "Masukkan Position dari SHOW MASTER STATUS: "
IFS= read -r MASTER_LOG_POS

# Validasi agar tidak salah menghubungkan jaringan.
case "$MASTER_IP" in
    192.233.4.*) ;;
    *)
        echo "ERROR: IP Master harus berada di Network 4 (192.233.4.0/24)."
        exit 1
        ;;
esac

case "$MASTER_LOG_FILE" in
    mariadb-bin.*) ;;
    *)
        echo "ERROR: Periksa kembali nama File binary log dari yaga."
        exit 1
        ;;
esac

case "$MASTER_LOG_POS" in
    ''|*[!0-9]*)
        echo "ERROR: Position harus berupa angka."
        exit 1
        ;;
esac

if ! command -v mariadbd >/dev/null 2>&1; then
    apt-get install -y mariadb-server mariadb-client
fi

mkdir -p "$BACKUP"

if [ -f "$CONF" ] && [ ! -f "$BACKUP/60-soal-13.cnf.before" ]; then
    cp -a "$CONF" "$BACKUP/60-soal-13.cnf.before"
fi

# Simpan konfigurasi Slave di /root.
cat > "$BACKUP/60-soal-13-slave.cnf" <<'CNF'
[mariadb]
server-id=45
relay-log=mariadb-relay-bin
read-only=ON
bind-address=0.0.0.0
CNF

install -m 0644 "$BACKUP/60-soal-13-slave.cnf" "$CONF"

echo "=== Restart MariaDB Slave ==="
service mariadb restart

# Buat struktur awal yang sama dengan Master.
mariadb -uroot <<'SQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_k44;

USE db_shibuya_k44;

CREATE TABLE IF NOT EXISTS request_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR(10) DEFAULT NULL,
    path VARCHAR(255) DEFAULT NULL,
    client_ip VARCHAR(45) DEFAULT NULL,
    status_code SMALLINT UNSIGNED DEFAULT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE USER IF NOT EXISTS
    'app_k44'@'192.233.4.%'
    IDENTIFIED BY 'AppK44_2026!';

GRANT SELECT, INSERT, UPDATE, DELETE
    ON db_shibuya_k44.*
    TO 'app_k44'@'192.233.4.%';

FLUSH PRIVILEGES;
SQL

# Hubungkan Slave ke Master menggunakan file dan posisi yang dicatat.
mariadb -uroot <<SQL
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
    MASTER_HOST='$MASTER_IP',
    MASTER_PORT=3306,
    MASTER_USER='repl_k44',
    MASTER_PASSWORD='ReplK44_2026!',
    MASTER_LOG_FILE='$MASTER_LOG_FILE',
    MASTER_LOG_POS=$MASTER_LOG_POS,
    MASTER_CONNECT_RETRY=5;

START SLAVE;
SQL

echo "=== Status replikasi Slave ==="
mariadb -uroot -e "SHOW SLAVE STATUS\G"

echo "Skrip: /root/soal-13.sh"
echo "Konfigurasi: $BACKUP/60-soal-13-slave.cnf"
echo "Backup konfigurasi sebelumnya: $BACKUP"
EOF

chmod +x /root/soal-13.sh
/root/soal-13.sh

#di yaga

mariadb -uroot

INSERT INTO db_shibuya_k44.request_logs
    (method, path, client_ip, status_code)
VALUES
    ('TEST', '/soal-13-replikasi', '192.233.4.250', 200);

SELECT *
FROM db_shibuya_k44.request_logs
WHERE path = '/soal-13-replikasi';

exit;

#cek data di slave inumaki

mariadb -uroot -e "
SELECT *
FROM db_shibuya_k44.request_logs
WHERE path = '/soal-13-replikasi';
"

#network 4, di inumaki

mariadb --protocol=TCP -h 192.233.4.8 -u app_k44 -p

pass : AppK44_2026!

#jalanin

SELECT COUNT(*) FROM db_shibuya_k44.request_logs;
exit;
