# Di node kusakabe, konfig jaringan

# 1. Pasang IP statis jika belum dapat DHCP
ip addr add 192.233.3.15/24 dev eth0 2>/dev/null
ip link set eth0 up
ip route add default via 192.233.3.1 2>/dev/null

# 2. Set resolver internet agar bisa mengunduh paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 3. Daftarkan domain jujutsu ke IP Gojo (192.233.1.4)
grep -q "jujutsu.k44.com" /etc/hosts || echo "192.233.1.4 jujutsu.k44.com www.jujutsu.k44.com" >> /etc/hosts

# pasang tool ab

apk update
apk add apache2-utils curl

# uji web frontend di kusakabe

ab -n 600 -c 30 http://jujutsu.k44.com/

# uji endpoint api di kusakabe

ab -n 600 -c 30 http://jujutsu.k44.com/api

# cek log di gojo

awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c

# periksa bukti blokir

grep "limiting requests" /var/log/nginx/error.log | tail -n 5

