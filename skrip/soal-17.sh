# masuk ke consol mariaDB di yaga

mariadb -u root -p

USE db_shibuya_k44;

-- Buat tabel request_logs jika belum ada
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(45) NOT NULL,
    worker VARCHAR(50),
    endpoint VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pastikan user app_k44 memiliki izin akses dari seluruh Network 4
GRANT ALL PRIVILEGES ON db_shibuya_k44.* TO 'app_k44'@'192.233.4.%' IDENTIFIED BY 'AppK44_2026!';
FLUSH PRIVILEGES;
EXIT;

# di gojo 

cat << 'EOF' > /etc/nginx/sites-available/jujutsu
upstream frontend_cluster {
    server 192.233.4.3:80;
    server 192.233.4.4:80;
}

upstream api_backend {
    server 192.233.4.2:80;
}

server {
    listen 80;
    server_name jujutsu.k44.com www.jujutsu.k44.com;

    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        rewrite ^/api/?(.*)$ /$1 break;
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t && service nginx reload

# di geto

cat << 'EOF' > /etc/nginx/sites-available/api_cluster
upstream api_cluster {
    server 192.233.4.5:80 weight=3;
    server 192.233.4.6:80 weight=1;
}

server {
    listen 80 default_server;
    server_name _;

    # Hanya percaya header IP dari IP node Gojo (192.233.1.4)
    set_real_ip_from 192.233.1.4;
    set_real_ip_from 192.233.1.0/24;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        # Meneruskan IP asli yang sudah divalidasi ke worker backend
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t && service nginx restart

# di node nanami & todo

cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: application/json');

// Mengambil IP asli dari header yang diteruskan proxy
$client_ip = $_SERVER['REMOTE_ADDR'];
if (!empty($_SERVER['HTTP_X_REAL_IP'])) {
    $client_ip = $_SERVER['HTTP_X_REAL_IP'];
} elseif (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
    $ips = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
    $client_ip = trim($ips[0]);
}

$worker_name = "nanami";
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
/etc/init.d/php8.4-fpm restart
chmod 777 /var/run/php/php8.4-fpm.sock

# validasi di itadori & ino

ip -4 a show eth0
curl -s http://jujutsu.k44.com/api

# cek di yaga

mariadb -u app_k44 -p'AppK44_2026!' -e "USE db_shibuya_k44; SELECT id, client_ip, worker, endpoint, created_at FROM request_logs ORDER BY id DESC LIMIT 10;"