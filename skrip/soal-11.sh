#Di Node utahime

cat > /root/soal-11.sh <<'SCRIPT'
#!/bin/sh
set -eu

# Nameserver untuk persiapan instalasi paket
printf 'nameserver 192.168.122.1\n' > /etc/resolv.conf

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils dnsutils

# Konfigurasi dasar DNS Master
cat > /etc/bind/named.conf.options <<'OPTIONS'
options {
    directory "/var/cache/bind";

    listen-on { any; };
    listen-on-v6 { any; };

    recursion no;
    allow-query { localhost; 192.233.0.0/16; };

    dnssec-validation auto;
};
OPTIONS

# Deklarasi zona utama
cat > /etc/bind/named.conf.local <<'LOCAL'
zone "jujutsu.k44.com" {
    type master;
    file "/etc/bind/db.jujutsu.k44.com";
    allow-transfer { 192.233.1.3; };
    also-notify { 192.233.1.3; };
};
LOCAL

# Isi zona DNS
cat > /etc/bind/db.jujutsu.k44.com <<'ZONE'
$TTL 86400
@ IN SOA utahime.jujutsu.k44.com. admin.jujutsu.k44.com. (
    2026101301
    3600
    900
    604800
    86400
)

@         IN NS  utahime.jujutsu.k44.com.
@         IN NS  shoko.jujutsu.k44.com.

utahime   IN A   192.233.1.2
shoko     IN A   192.233.1.3

sync-test IN TXT "dns-zone-sync-k44-v1"
ZONE

# Validasi sebelum menjalankan layanan
named-checkconf
named-checkzone jujutsu.k44.com /etc/bind/db.jujutsu.k44.com

# Terapkan konfigurasi
service bind9 restart

echo "Konfigurasi DNS Master selesai."
SCRIPT

chmod +x /root/soal-11.sh

#jalankan
bash /root/soal-11.sh
#cek layanan
service bind9 status
#uji dns master
dig @127.0.0.1 jujutsu.k44.com SOA


#DI shoko

cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { any; };
    recursion no;
    allow-query { localhost; 192.233.0.0/16; };
    dnssec-validation auto;
};
EOF

cat > /etc/bind/named.conf.local <<'EOF'
zone "jujutsu.k44.com" {
    type slave;
    masters { 192.233.1.2; };
    file "/var/cache/bind/db.jujutsu.k44.com";
};
EOF

named-checkconf
service named restart

#uji transfer zone
dig @127.0.0.1 jujutsu.k44.com SOA +short
dig @127.0.0.1 jujutsu.k44.com NS +short

#jalankan di utahime
sed -i \
  -e 's/2026101301/2026101302/' \
  -e 's/dns-zone-sync-k44-v1/dns-zone-sync-k44-v2/' \
  /etc/bind/db.jujutsu.k44.com

named-checkzone jujutsu.k44.com /etc/bind/db.jujutsu.k44.com
service named restart

#di shoko
dig @127.0.0.1 jujutsu.k44.com SOA +short
dig @127.0.0.1 sync-test.jujutsu.k44.com TXT +short

#verif dari client
dig @192.233.1.2 jujutsu.k44.com SOA +short
dig @192.233.1.3 jujutsu.k44.com SOA +short
dig @192.233.1.3 sync-test.jujutsu.k44.com TXT +short