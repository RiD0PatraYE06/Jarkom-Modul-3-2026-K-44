# Di Maki

echo "nameserver 192.168.122.1" > /etc/resolv.conf
mkdir -p /var/www/html
apt-get update && apt-get install -y nginx curl

# Buat halaman frontend Maki
cat << 'EOF' > /var/www/html/index.html
Frontend Response: MAKI (Worker Frontend 1)
EOF

# Izinkan localhost dan Gojo (192.233.1.4), tolak akses langsung lainnya
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.htm;
    server_name _;

    allow 127.0.0.1;
    allow ::1;
    allow 192.233.1.4; # Ganti dengan IP Gojo Anda
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

nginx -t && service nginx restart

# di panda

echo "nameserver 192.168.122.1" > /etc/resolv.conf
mkdir -p /var/www/html
apt-get update && apt-get install -y nginx curl

# Buat halaman frontend Panda
cat << 'EOF' > /var/www/html/index.html
Frontend Response: PANDA (Worker Frontend 2)
EOF

# Izinkan localhost dan Gojo (192.233.1.4), tolak akses langsung lainnya
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.htm;
    server_name _;

    allow 127.0.0.1;
    allow ::1;
    allow 192.233.1.4; # Ganti dengan IP Gojo Anda
    deny all;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

nginx -t && service nginx restart

# di gojo 

echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install -y nginx curl

rm -f /etc/nginx/sites-enabled/default

# konfig

cat << 'EOF' > /etc/nginx/sites-available/jujutsu
# Upstream Frontend: Round Robin maki & panda
upstream frontend_cluster {
    server 192.233.4.3:80; # IP maki
    server 192.233.4.4:80; # IP panda
}

# Upstream API: Load Balancer Geto
upstream api_backend {
    server 192.233.4.2:80; # IP geto
}

server {
    listen 80;
    server_name jujutsu.k44.com www.jujutsu.k44.com;

    # 1. Routing Root (/) ke Worker Frontend (Round Robin Maki/Panda)
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 2. Routing Path /api ke Internal Load Balancer Geto
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

# aktifkan

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/
nginx -t
service nginx restart

# pengujian dri ino

for i in {1..6}; do
    curl -s http://jujutsu.k44.com/
done


for i in {1..8}; do
    curl -s http://jujutsu.k44.com/api
done

