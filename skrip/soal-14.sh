#Di Node yaga

mariadb -u root

SHOW DATABASES LIKE 'db_shibuya_k44';

USE db_shibuya_k44;

DESCRIBE request_logs;

SELECT User, Host
FROM mysql.user
WHERE User = 'app_k44';

#jalanin

CREATE USER IF NOT EXISTS 'apiuser'@'192.233.4.%'
IDENTIFIED BY 'ApiLab2026Change';

ALTER USER 'apiuser'@'192.233.4.%'
IDENTIFIED BY 'ApiLab2026Change';

GRANT SELECT, INSERT, UPDATE, DELETE
ON db_shibuya_k44.*
TO 'apiuser'@'192.233.4.%';

FLUSH PRIVILEGES;

EXIT;

#di maki & panda buat =

cat > /root/q14_frontend.sh <<'SCRIPT'
#!/bin/bash
set -Eeuo pipefail

GROUP="k44"
DOMAIN="jujutsu.${GROUP}.com"

read -rp "Nama worker (maki/panda): " WORKER_NAME
read -rp "IP Gojo pada Network 1: " GOJO_IP

if [[ "$WORKER_NAME" != "maki" && "$WORKER_NAME" != "panda" ]]; then
    echo "ERROR: Nama worker harus maki atau panda."
    exit 1
fi

if [[ ! "$GOJO_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "ERROR: Format IP Gojo tidak valid."
    exit 1
fi

echo "=== Instalasi frontend ==="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    nginx php-fpm php-mysql

# Set hostname agar hasil halaman sesuai nama node.
printf '%s\n' "$WORKER_NAME" > /etc/hostname
hostname "$WORKER_NAME"

# Temukan service PHP-FPM yang terpasang.
FPM_INIT="$(find /etc/init.d -maxdepth 1 \
    -type f -name 'php*-fpm' -print -quit)"

if [ -n "$FPM_INIT" ]; then
    service "$(basename "$FPM_INIT")" restart
fi

PHP_SOCKET="$(find /run/php -maxdepth 1 \
    -type s -name 'php*-fpm.sock' -print -quit)"

if [ -z "$PHP_SOCKET" ]; then
    echo "ERROR: Socket PHP-FPM tidak ditemukan."
    ls -la /run/php/ || true
    exit 1
fi

mkdir -p /root/backup-q14 /var/www/html

# Backup default site jika belum pernah disimpan.
if [ -f /etc/nginx/sites-available/default ] &&
   [ ! -f /root/backup-q14/nginx-default.before ]; then
    cp -a /etc/nginx/sites-available/default \
        /root/backup-q14/nginx-default.before
fi

# Halaman frontend yang menampilkan hostname.
cat > /var/www/html/index.php <<'PHP'
<?php
header('Content-Type: text/plain; charset=utf-8');
echo "Frontend worker: " . gethostname() . PHP_EOL;
PHP

# Virtual host frontend.
cat > /etc/nginx/sites-available/q14-frontend <<NGINX
server {
    listen 80 default_server;
    server_name ${DOMAIN} www.${DOMAIN};

    root /var/www/html;
    index index.php index.html;

    # Hanya Gojo yang boleh mengakses frontend worker.
    allow ${GOJO_IP};
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:${PHP_SOCKET};
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/q14-frontend \
    /etc/nginx/sites-enabled/q14-frontend

chown -R www-data:www-data /var/www/html

echo "=== Validasi dan restart Nginx ==="
php -l /var/www/html/index.php
nginx -t
service nginx restart
service nginx status

echo "Frontend ${WORKER_NAME} selesai dikonfigurasi."
SCRIPT

bash /root/q14_frontend.sh

# uji di node gojo

curl -i -H "Host: jujutsu.k44.com" http://IP_MAKI/
curl -i -H "Host: www.jujutsu.k44.com" http://IP_PANDA/

# buat script di nanami , todo, kirara 

cat > /root/q14_api_worker.sh <<'SCRIPT'
#!/bin/bash
set -Eeuo pipefail

GROUP="k44"
DOMAIN="jujutsu.${GROUP}.com"
DB_NAME="db_shibuya_${GROUP}"
DB_USER="apiuser"

read -rp "Nama worker (nanami/todo/kirara): " WORKER_NAME
read -rp "IP Geto pada Network 4: " GETO_IP
read -rp "IP Yaga pada Network 4: " YAGA_IP
read -rsp "Password apiuser pada Yaga: " DB_PASSWORD
echo

case "$WORKER_NAME" in
    nanami|todo|kirara) ;;
    *)
        echo "ERROR: Nama worker harus nanami, todo, atau kirara."
        exit 1
        ;;
esac

for IP_VALUE in "$GETO_IP" "$YAGA_IP"; do
    if [[ ! "$IP_VALUE" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "ERROR: Format IP tidak valid: $IP_VALUE"
        exit 1
    fi
done

# Gunakan password yang sama dengan akun di Yaga.
# Base64 menghindari masalah kutip saat menulis konfigurasi PHP.
DB_PASSWORD_B64="$(printf '%s' "$DB_PASSWORD" | base64 | tr -d '\n')"
unset DB_PASSWORD

echo "=== Instalasi API worker ==="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    nginx php-fpm php-mysql

# Set hostname agar log menunjukkan worker yang benar.
printf '%s\n' "$WORKER_NAME" > /etc/hostname
hostname "$WORKER_NAME"

FPM_INIT="$(find /etc/init.d -maxdepth 1 \
    -type f -name 'php*-fpm' -print -quit)"

if [ -n "$FPM_INIT" ]; then
    service "$(basename "$FPM_INIT")" restart
fi

PHP_SOCKET="$(find /run/php -maxdepth 1 \
    -type s -name 'php*-fpm.sock' -print -quit)"

if [ -z "$PHP_SOCKET" ]; then
    echo "ERROR: Socket PHP-FPM tidak ditemukan."
    ls -la /run/php/ || true
    exit 1
fi

mkdir -p /root/backup-q14 /var/www/api

if [ -f /etc/nginx/sites-available/default ] &&
   [ ! -f /root/backup-q14/nginx-default.before ]; then
    cp -a /etc/nginx/sites-available/default \
        /root/backup-q14/nginx-default.before
fi

# Konfigurasi koneksi database.
cat > /var/www/api/config.php <<PHP_CONFIG
<?php
return [
    'host' => '${YAGA_IP}',
    'database' => '${DB_NAME}',
    'username' => '${DB_USER}',
    'password' => base64_decode('${DB_PASSWORD_B64}'),
];
PHP_CONFIG

unset DB_PASSWORD_B64

# Endpoint API yang mencatat request ke database.
cat > /var/www/api/index.php <<'PHP'
<?php

header('Content-Type: application/json; charset=utf-8');

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$path = parse_url(
    $_SERVER['REQUEST_URI'] ?? '/',
    PHP_URL_PATH
) ?: '/';

$worker = gethostname();
$clientIp = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$statusCode = 200;

try {
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

    $cfg = require __DIR__ . '/config.php';

    $db = new mysqli(
        $cfg['host'],
        $cfg['username'],
        $cfg['password'],
        $cfg['database']
    );

    $db->set_charset('utf8mb4');

    $stmt = $db->prepare(
        'INSERT INTO request_logs
         (method, path, client_ip, worker, status_code)
         VALUES (?, ?, ?, ?, ?)'
    );

    $stmt->bind_param(
        'ssssi',
        $method,
        $path,
        $clientIp,
        $worker,
        $statusCode
    );

    $stmt->execute();
    $stmt->close();
    $db->close();

    echo json_encode([
        'status' => 'ok',
        'worker' => $worker,
        'path' => $path,
        'client_ip' => $clientIp
    ], JSON_UNESCAPED_SLASHES), PHP_EOL;

} catch (Throwable $e) {
    error_log($e->getMessage());
    http_response_code(500);

    echo json_encode([
        'status' => 'error',
        'message' => 'Database logging failed'
    ], JSON_UNESCAPED_SLASHES), PHP_EOL;
}
PHP

# Virtual host API.
cat > /etc/nginx/sites-available/q14-api <<NGINX
server {
    listen 80 default_server;
    server_name ${DOMAIN} www.${DOMAIN} api.${DOMAIN};

    root /var/www/api;
    index index.php;

    # Hanya Geto yang boleh mengakses API worker.
    allow ${GETO_IP};
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:${PHP_SOCKET};
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/q14-api \
    /etc/nginx/sites-enabled/q14-api

chown -R www-data:www-data /var/www/api
chmod 640 /var/www/api/config.php

echo "=== Validasi konfigurasi ==="
php -l /var/www/api/config.php
php -l /var/www/api/index.php
php -m | grep -i mysqli
nginx -t

service nginx restart
service nginx status

echo "API worker ${WORKER_NAME} selesai dikonfigurasi."
SCRIPT

bash /root/q14_api_worker.sh

# uji hasil API di geto

curl -i -H "Host: jujutsu.k44.com" http://IP_NANAMI/api
curl -i -H "Host: jujutsu.k44.com" http://IP_TODO/api
curl -i -H "Host: jujutsu.k44.com" http://IP_KIRARA/api

# dari salah satu klien di network 2 / 3

curl -i http://IP_MAKI/
curl -i http://IP_PANDA/

curl -i http://IP_NANAMI/api
curl -i http://IP_TODO/api
curl -i http://IP_KIRARA/api

