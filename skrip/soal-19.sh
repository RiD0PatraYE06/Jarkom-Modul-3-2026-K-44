# Di gojo

mkdir -p /var/cache/nginx/jujutsu_cache
chown -R www-data:www-data /var/cache/nginx

# konfig

cat << 'EOF' > /etc/nginx/sites-available/jujutsu
# 1. Deklarasi Cache Path: masa simpan 10 menit di memori zone, storage 100m
proxy_cache_path /var/cache/nginx/jujutsu_cache levels=1:2 keys_zone=jujutsu_cache:10m inactive=60m max_size=100m;

# 2. Deklarasi Rate Limiting: 10 request/detik per IP klien ($binary_remote_addr)
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# Upstream Frontend (Maki & Panda)
upstream frontend_cluster {
    server 192.233.4.3:80;
    server 192.233.4.4:80;
}

# Upstream API (Internal LB Geto)
upstream api_backend {
    server 192.233.4.2:80;
}

server {
    listen 80;
    server_name jujutsu.k44.com www.jujutsu.k44.com;

    # ==========================================
    # Web Frontend (Root /) dengan Proxy Caching
    # ==========================================
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Konfigurasi Cache 10 Menit
        proxy_cache jujutsu_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid any 1m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;

        # Pastikan Nginx meng-cache konten statis & dinamis frontend
        proxy_ignore_headers Cache-Control Expires Set-Cookie;

        # Header verifikasi status cache (MISS / HIT)
        add_header X-Cache-Status $upstream_cache_status;
    }

    # ==========================================
    # API Backend (/api) dengan Rate Limiting 10r/s
    # ==========================================
    location /api {
        # Batasi 10 req/s, toleransi burst 10 request instan tanpa delay
        limit_req zone=api_limit burst=10 nodelay;

        rewrite ^/api/?(.*)$ /$1 break;
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# validasi

nginx -t
service nginx restart

# di gojo

cat << 'EOF' > /root/setup_proxy.sh
#!/bin/bash

# Setup Resolver & Direktori Cache
echo "nameserver 192.168.122.1" > /etc/resolv.conf
mkdir -p /var/cache/nginx/jujutsu_cache
chown -R www-data:www-data /var/cache/nginx

# Bersihkan default site
rm -f /etc/nginx/sites-enabled/default

# Tulis konfigurasi jujutsu
cat << 'CONF' > /etc/nginx/sites-available/jujutsu
proxy_cache_path /var/cache/nginx/jujutsu_cache levels=1:2 keys_zone=jujutsu_cache:10m inactive=60m max_size=100m;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

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

        proxy_cache jujutsu_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid any 1m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_ignore_headers Cache-Control Expires Set-Cookie;
        add_header X-Cache-Status $upstream_cache_status;
    }

    location /api {
        limit_req zone=api_limit burst=10 nodelay;

        rewrite ^/api/?(.*)$ /$1 break;
        proxy_pass http://api_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
CONF

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/
nginx -t && service nginx restart
echo "Proxy Gojo (Caching & Rate Limiting) siap digunakan."
EOF

chmod +x /root/setup_proxy.sh

# uji proxy caching dari itadori

curl -i http://jujutsu.k44.com/ | grep -E "HTTP|X-Cache-Status|Frontend"

# HIT

curl -i http://jujutsu.k44.com/ | grep -E "HTTP|X-Cache-Status|Frontend"

# uji normal di itadori

curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k44.com/api
curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k44.com/api
curl -s -o /dev/null -w "%{http_code}\n" http://jujutsu.k44.com/api

# uji flooding

for i in {1..25}; do
    curl -s -o /dev/null -w "Req $i: HTTP Status %{http_code}\n" http://jujutsu.k44.com/api
done

# verif log penolakan di gojo

tail -n 10 /var/log/nginx/error.log

