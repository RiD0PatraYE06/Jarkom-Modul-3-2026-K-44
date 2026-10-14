# DI kirara

echo "nameserver 192.168.122.1" > /etc/resolv.conf
rm -f /etc/apt/sources.list.d/*.sources 2>/dev/null

cat << 'EOF' > /etc/apt/sources.list
deb [trusted=yes] http://deb.debian.org/debian trixie main
deb [trusted=yes] http://deb.debian.org/debian trixie-updates main
EOF
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

apt-get update
apt-get install -y nginx php-fpm php-mysql curl

# buat skrip API

mkdir -p /var/www/html

cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: application/json');

$client_ip = $_SERVER['REMOTE_ADDR'];
if (!empty($_SERVER['HTTP_X_REAL_IP'])) {
    $client_ip = $_SERVER['HTTP_X_REAL_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
    $client_ip = trim($ips[0]);
}

$worker_name = "kirara";
$db_host = "192.233.4.11"; // Ganti jika IP yaga berbeda
$db_user = "app_k44";
$db_pass = "AppK44_2026!";
$db_name = "db_shibuya_k44";

$db_status = "unrecorded";

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 3
    ]);

    $stmt = $pdo->prepare("INSERT INTO request_logs (client_ip, worker, endpoint) VALUES (:ip, :worker, :endpoint)");
    $stmt->execute([
        ':ip' => $client_ip,
        ':worker' => $worker_name,
        ':endpoint' => $_SERVER['REQUEST_URI']
    ]);
    $db_status = "logged_successfully";
} catch (Exception $e) {
    $db_status = "error: " . $e->getMessage();
}

echo json_encode([
    "worker" => $worker_name,
    "hostname" => gethostname(),
    "recorded_client_ip" => $client_ip,
    "database_logging" => $db_status
], JSON_PRETTY_PRINT) . "\n";
?>
EOF

chmod 644 /var/www/html/index.php

# konfig nginx virtual host

/etc/init.d/php*-fpm restart
SOCK=$(ls /var/run/php/php*-fpm.sock 2>/dev/null | head -n 1)

cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;
    server_name _;

    # Access control: Hanya localhost dan geto
    allow 127.0.0.1;
    allow ::1;
    allow 192.233.4.2;
    deny all;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$SOCK;
    }
}
EOF

chmod 777 $SOCK 2>/dev/null
nginx -t && service nginx restart

# uji

curl -i http://localhost/

# Di geto perbarui konfg VH

cat << 'EOF' > /etc/nginx/sites-available/api_cluster
upstream api_cluster {
    # Worker API utama dengan Passive Health Check
    server 192.233.4.5:80 weight=3 max_fails=2 fail_timeout=5s;
    server 192.233.4.6:80 weight=1 max_fails=2 fail_timeout=5s;

    # Worker API cadangan (hanya aktif jika kedua server utama down)
    server 192.233.4.7:80 backup;
}

server {
    listen 80 default_server;
    server_name _;

    # Real-IP dari reverse proxy Gojo
    set_real_ip_from 192.233.1.4;
    set_real_ip_from 192.233.1.0/24;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Pengalihan instan ke backup jika server utama error/down
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;
    }
}
EOF

# validasi 

nginx -t
service nginx restart

# perbarui skrip

cat << 'EOF' > /root/setup_lb.sh
#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
nginx -t && service nginx restart
echo "Internal Load Balancer Geto aktif dengan konfigurasi High Availability (Kirara backup)."
EOF
chmod +x /root/setup_lb.sh

# uji dari itadori

for i in {1..8}; do
    curl -s http://jujutsu.k44.com/api | grep '"worker"'
done

# matikan nginx di nanami dan todo

service nginx stop

# di itadori

curl -i http://jujutsu.k44.com/api

for i in {1..5}; do
    curl -s http://jujutsu.k44.com/api | grep '"worker"'
done

# nyalain nginx

service nginx start

# dari itadori

for i in {1..8}; do
 curl -s http://jujutsu.k44.com/api | grep '"worker"'
done

# cek log yaga

mariadb -u app_k44 -p'AppK44_2026!' -e "USE db_shibuya_k44; SELECT id, client_ip, worker, endpoint, created_at FROM request_logs ORDER BY id DESC LIMIT 10;"