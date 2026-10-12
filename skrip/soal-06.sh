# Skrip lengkap soal 6

# ===========================================================
# terminal
# ===========================================================

# kugisaki
# ===========================================================
ip link show eth0

# hasil mac address kugisaki
# ===========================================================
kugisaki:~# ip link show eth0
65131: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:7b:ca:88:00 brd ff:ff:ff:ff:ff:ff
kugisaki:~#

# ringkasan dari hasil mac address kugisaki
# ===========================================================
# MAC kugisaki = 02:42:7b:ca:88:00

# tengen
# ===========================================================

# buat skrip soal-06.sh
# ===========================================================
nano /root/soal-06.sh

# isi file soal-06.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 6 - Setup Static Lease VIP kugisaki (tengen)
# Kelompok: K44 | Prefix: 192.233 | Domain: k44.com
# ========================================================

# MAC Address Client Network 3
MAC_INO="02:42:10:24:ba:00"
MAC_KUSAKABE="02:42:06:f2:a9:00"
MAC_MIWA="02:42:e2:8b:19:00"

# MAC Address VIP kugisaki (GANTI DENGAN HASIL 'ip link show eth0' KUGISAKI)
MAC_KUGISAKI="02:42:7b:ca:88:00"

cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

# --- CLASS DIVISI A (NETWORK 2 - SOAL 4) ---
class "pool1_dev" {
    match if hardware = 1:02:42:47:97:d1:00 or hardware = 1:02:42:bb:96:e3:00;
}

class "pool2_support" {
    match if hardware = 1:02:42:43:f9:6b:00 or hardware = 1:02:42:7a:09:9a:00;
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

    pool {
        allow members of "pool1_dev";
        range 192.233.2.10 192.233.2.35;
    }

    pool {
        allow members of "pool2_support";
        range 192.233.2.70 192.233.2.95;
    }
}

# Subnet Network 3 (Divisi B)
subnet 192.233.3.0 netmask 255.255.255.0 {
    option routers 192.233.3.1;
    option broadcast-address 192.233.3.255;

    option domain-name-servers 192.233.1.2, 192.233.1.3;
    option domain-name "k44.com";
    option domain-search "k44.com";

    # Pool Short Lease (ino & kusakabe)
    pool {
        allow members of "short_lease_class";
        range 192.233.3.10 192.233.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool Long Lease (miwa)
    pool {
        allow members of "long_lease_class";
        range 192.233.3.100 192.233.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
EOF

# Validasi & Restart Service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart

echo "[OK] Setup Static Lease VIP Soal 6 berhasil di tengen."

# bash manual
# ===========================================================
bash /root/soal-06.sh

# di terminal client (kugisaki) jalankan perintah berikut
# ===========================================================
ifdown eth0 && ifup eth0
ip a

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