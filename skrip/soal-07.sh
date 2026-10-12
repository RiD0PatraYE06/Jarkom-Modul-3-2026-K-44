# Skrip lengkap soal 7

# ===========================================================
# terminal
# ===========================================================

# tengen
# ===========================================================

# buat skrip soal-07.sh
# ===========================================================
nano /root/soal-07.sh

# isi file soal-07.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 7 - Global DHCP Config & Final Verification (tengen)
# Kelompok: K44 | Prefix: 192.233 | Domain: k44.com
# ========================================================

# MAC Address Divisi A (Network 2)
MAC_ITADORI="02:42:47:97:d1:00"
MAC_FUSHIGURO="02:42:bb:96:e3:00"
MAC_ZENIN="02:42:43:f9:6b:00"
MAC_OKKOTSU="02:42:7a:09:9a:00"

# MAC Address Divisi B (Network 3)
MAC_INO="02:42:10:24:ba:00"
MAC_KUSAKABE="02:42:06:f2:a9:00"
MAC_MIWA="02:42:e2:8b:19:00"
MAC_KUGISAKI="02:42:7b:ca:88:00"

cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

# --- GLOBAL OPTIONS (SOAL 7: Dipakai oleh Divisi A & Divisi B) ---
option domain-name-servers 192.233.1.2, 192.233.1.3;
option domain-name "k44.com";
option domain-search "k44.com";

# --- CLASS DIVISI A (NETWORK 2 - SOAL 4) ---
class "pool1_dev" {
    match if hardware = 1:$MAC_ITADORI or hardware = 1:$MAC_FUSHIGURO;
}

class "pool2_support" {
    match if hardware = 1:$MAC_ZENIN or hardware = 1:$MAC_OKKOTSU;
}

# --- CLASS DIVISI B (NETWORK 3 - SOAL 5) ---
class "short_lease_class" {
    match if hardware = 1:$MAC_INO or hardware = 1:$MAC_KUSAKABE;
}

class "long_lease_class" {
    match if hardware = 1:$MAC_MIWA;
}

# --- STATIC LEASE VIP (NETWORK 3 - SOAL 6) ---
host kugisaki_vip {
    hardware ethernet $MAC_KUGISAKI;
    fixed-address 192.233.3.99;
}

# Subnet Lokal Network 4 (Data Center)
subnet 192.233.4.0 netmask 255.255.255.0 {
    option routers 192.233.4.1;
    option broadcast-address 192.233.4.255;
}

# Subnet Network 2 (Divisi A)
subnet 192.233.2.0 netmask 255.255.255.0 {
    option routers 192.233.2.1;
    option broadcast-address 192.233.2.255;

    # Pool 1 (Dev): 192.233.2.10 - 192.233.2.35
    pool {
        allow members of "pool1_dev";
        range 192.233.2.10 192.233.2.35;
    }

    # Pool 2 (Support): 192.233.2.70 - 192.233.2.95
    pool {
        allow members of "pool2_support";
        range 192.233.2.70 192.233.2.95;
    }
}

# Subnet Network 3 (Divisi B)
subnet 192.233.3.0 netmask 255.255.255.0 {
    option routers 192.233.3.1;
    option broadcast-address 192.233.3.255;

    # Pool Short Lease (ino & kusakabe) - 30 Menit
    pool {
        allow members of "short_lease_class";
        range 192.233.3.10 192.233.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool Long Lease (miwa) - 12 Jam
    pool {
        allow members of "long_lease_class";
        range 192.233.3.100 192.233.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
EOF

# Validasi & Restart
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart

echo "[OK] DHCP Server Soal 7 berhasil dikonfigurasi di tengen."

# bash manual
# ===========================================================
bash /root/soal-07.sh

# jalankan perintah berikut di semua client (itadori, fushiguro, zenin, okkotsu, ino, kusakabe, miwa, kugisaki)
# ===========================================================
ifdown eth0 && ifup eth0

# verifikasi routing dan dns di client
# ===========================================================

# tes di itadori
# ===========================================================
ip route
cat /etc/resolv.conf

# tes di ino
# ===========================================================
ip route
cat /etc/resolv.conf

# verifikasi tabel lease di tengen
# ===========================================================
cat /var/lib/dhcp/dhcpd.leases

# ==========================================================
# interface
# ==========================================================

# tengen
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.10
	netmask 255.255.255.0
	gateway 192.233.4.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

	up bash /root/soal-02.sh
	up bash /root/soal-04.sh
	up bash /root/soal-05.sh
	up bash /root/soal-06.sh
    up bash /root/soal-07.sh