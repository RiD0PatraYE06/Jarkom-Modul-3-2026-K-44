# Di node nanami & todo

cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: application/json');
echo json_encode([
    "worker" => "nanami" // ganti sesuai nama node (nanami, todo)
    "hostname" => gethostname(),
    "status" => "API Active"
]) . "\n";
?>
EOF

#jalankkan

cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    # Pembatasan akses (Hanya localhost dan Geto yang diizinkan)
    allow 127.0.0.1;
    allow 192.233.4.2;
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    }
}
EOF

# uji

nginx -t && service nginx restart
curl -i http://localhost/

# Di geto 

apt-get update
apt-get install -y nginx curl

rm -f /etc/nginx/sites-enabled/default

# konfig

cat << 'EOF' > /etc/nginx/sites-available/api_cluster
upstream api_cluster {
    # nanami menerima beban 3x lebih banyak dibanding todo
    server 192.233.4.5:80 weight=3;
    server 192.233.4.6:80 weight=1;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeout koneksi agar responsif
        proxy_connect_timeout 5s;
        proxy_read_timeout 10s;
    }
}
EOF

# aktifkan

ln -sf /etc/nginx/sites-available/api_cluster /etc/nginx/sites-enabled/
nginx -t
service nginx restart

# tes di inumaki

for i in {1..20}; do
    curl -s http://192.233.4.2/
done

# tes 2

for i in {1..40}; do
    curl -s http://192.233.4.2/ | grep -o '"worker":"[^"]*"'
done | sort | uniq -c