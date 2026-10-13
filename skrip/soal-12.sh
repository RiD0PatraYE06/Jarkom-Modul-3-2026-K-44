#Di Node utahime


cat > /root/soal-12.sh <<'EOF'
#!/bin/sh
set -eu

DOMAIN="jujutsu.k44.com"
GOJO_IP="192.233.1.4"
GOJO_LAST="${GOJO_IP##*.}"
ZONE="/etc/bind/db.jujutsu.k44.com"
REV_ZONE="1.233.192.in-addr.arpa"
REV_FILE="/etc/bind/db.192.233.1"
BACKUP="/root/soal-12"

case "$GOJO_IP" in
    192.233.1.*) ;;
    *)
        echo "ERROR: IP Gojo harus berada di Network 1 (192.233.1.0/24)."
        exit 1
        ;;
esac

mkdir -p "$BACKUP"

# Cadangkan konfigurasi aktif sebelum perubahan.
for f in named.conf.options named.conf.local db.jujutsu.k44.com; do
    if [ -f "/etc/bind/$f" ]; then
        cp -a "/etc/bind/$f" "$BACKUP/$f"
    fi
done

if [ ! -f "$ZONE" ]; then
    echo "ERROR: File zona nomor 11 tidak ditemukan: $ZONE"
    exit 1
fi

# Ambil serial zona yang sekarang, kemudian naikkan satu.
OLD_SERIAL=$(awk '
    /SOA/ { inside=1; next }
    inside && /^[[:space:]]*[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][[:space:]]*$/ {
        gsub(/[[:space:]]/, "")
        print
        exit
    }
' "$ZONE")

if [ -z "$OLD_SERIAL" ]; then
    echo "ERROR: Nomor serial SOA tidak berhasil dibaca."
    exit 1
fi

NEXT_SERIAL=$((OLD_SERIAL + 1))

# Aktifkan recursive DNS melalui forwarder gateway.
cat > /etc/bind/named.conf.options <<'OPTIONS'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { any; };

    recursion yes;
    allow-query { localhost; 192.233.0.0/16; };
    allow-recursion { localhost; 192.233.0.0/16; };
    allow-query-cache { localhost; 192.233.0.0/16; };

    forwarders { 192.168.122.1; };
    forward only;

    dnssec-validation auto;
};
OPTIONS

# Zona utama dan zona Reverse DNS.
cat > /etc/bind/named.conf.local <<'LOCAL'
zone "jujutsu.k44.com" {
    type master;
    file "/etc/bind/db.jujutsu.k44.com";
    allow-transfer { 192.233.1.3; };
    also-notify { 192.233.1.3; };
};

zone "1.233.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.233.1";
    allow-transfer { 192.233.1.3; };
    also-notify { 192.233.1.3; };
};
LOCAL

# Zona forward: domain utama mengarah ke Gojo dan www menjadi CNAME.
cat > "$ZONE" <<ZONEFILE
\$TTL 86400
@ IN SOA utahime.jujutsu.k44.com. admin.jujutsu.k44.com. (
    $NEXT_SERIAL
    3600
    900
    604800
    86400
)

@       IN NS utahime.jujutsu.k44.com.
@       IN NS shoko.jujutsu.k44.com.
@       IN A  $GOJO_IP

www     IN CNAME jujutsu.k44.com.
utahime IN A 192.233.1.2
shoko   IN A 192.233.1.3
gojo    IN A $GOJO_IP

sync-test IN TXT "dns-zone-sync-k44-v2"
ZONEFILE

# Zona reverse /24: IP Gojo dapat ditelusuri ke domain utama.
cat > "$REV_FILE" <<REVFILE
\$TTL 86400
@ IN SOA utahime.jujutsu.k44.com. admin.jujutsu.k44.com. (
    $NEXT_SERIAL
    3600
    900
    604800
    86400
)

@ IN NS utahime.jujutsu.k44.com.
@ IN NS shoko.jujutsu.k44.com.
$GOJO_LAST IN PTR jujutsu.k44.com.
REVFILE

echo "=== Pemeriksaan konfigurasi ==="
named-checkconf
named-checkzone "$DOMAIN" "$ZONE"
named-checkzone "$REV_ZONE" "$REV_FILE"

echo "=== Restart DNS Master ==="
service named restart

echo "=== Hasil uji lokal Master ==="
dig @127.0.0.1 jujutsu.k44.com A +short
dig @127.0.0.1 www.jujutsu.k44.com CNAME +short
dig @127.0.0.1 -x "$GOJO_IP" +short

echo "=== Nomor serial baru: $NEXT_SERIAL ==="
echo "Backup konfigurasi lama: $BACKUP"
echo "Skrip tersimpan: /root/soal-12.sh"
EOF

chmod +x /root/soal-12.sh
/root/soal-12.sh

#verif
dig @127.0.0.1 jujutsu.k44.com A +short
dig @127.0.0.1 www.jujutsu.k44.com CNAME +short
dig @127.0.0.1 -x 192.233.1.4 +short

#Konfig slave, shoko

cat > /root/soal-12.sh <<'EOF'
#!/bin/sh
set -eu

BACKUP="/root/soal-12"
mkdir -p "$BACKUP"

# Cadangkan konfigurasi sebelumnya.
for f in named.conf.options named.conf.local; do
    if [ -f "/etc/bind/$f" ]; then
        cp -a "/etc/bind/$f" "$BACKUP/$f"
    fi
done

if [ -f /var/cache/bind/db.jujutsu.k44.com ]; then
    cp -a /var/cache/bind/db.jujutsu.k44.com \
        "$BACKUP/db.jujutsu.k44.com.before"
fi

# Forwarder untuk pencarian domain internet.
cat > /etc/bind/named.conf.options <<'OPTIONS'
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { any; };

    recursion yes;
    allow-query { localhost; 192.233.0.0/16; };
    allow-recursion { localhost; 192.233.0.0/16; };
    allow-query-cache { localhost; 192.233.0.0/16; };

    forwarders { 192.168.122.1; };
    forward only;

    dnssec-validation auto;
};
OPTIONS

# Terima kedua zona dari DNS Master utahime.
cat > /etc/bind/named.conf.local <<'LOCAL'
zone "jujutsu.k44.com" {
    type slave;
    masters { 192.233.1.2; };
    file "/var/cache/bind/db.jujutsu.k44.com";
};

zone "1.233.192.in-addr.arpa" {
    type slave;
    masters { 192.233.1.2; };
    file "/var/cache/bind/db.1.233.192";
};
LOCAL

named-checkconf
service named restart

echo "Skrip tersimpan: /root/soal-12.sh"
echo "Backup konfigurasi: $BACKUP"
EOF

chmod +x /root/soal-12.sh
/root/soal-12.sh

#verif
dig @127.0.0.1 jujutsu.k44.com SOA +short
dig @127.0.0.1 jujutsu.k44.com A +short
dig @127.0.0.1 www.jujutsu.k44.com CNAME +short
dig @127.0.0.1 -x 192.233.1.4 +short

#uji dri client (itadori)

dig @192.233.1.2 jujutsu.k44.com A +short
dig @192.233.1.2 www.jujutsu.k44.com CNAME +short
dig @192.233.1.2 -x 192.233.1.4 +short

#uji dri dns slave (shoko)

dig @192.233.1.3 jujutsu.k44.com A +short
dig @192.233.1.3 www.jujutsu.k44.com CNAME +short
dig @192.233.1.3 -x 192.233.1.4 +short

#Di client (itadori) uji dns 

dig @192.233.1.2 google.com A +short
dig @192.233.1.3 google.com A +short

ping -c 4 google.com