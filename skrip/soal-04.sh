# Skrip lengkap soal 4

# ===========================================================
# terminal
# ===========================================================

# itadori, fushiguro, zenin, okkotsu
# ===========================================================
ip link show eth0

# hasil mac address masing-masing node
# ===========================================================

# mac address itadori
# ===========================================================
itadori:~# ip link show eth0
63827: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:47:97:d1:00 brd ff:ff:ff:ff:ff:ff
itadori:~#

# mac address fushiguro
# ===========================================================
fushiguro:~# ip link show eth0
63835: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:bb:96:e3:00 brd ff:ff:ff:ff:ff:ff
fushiguro:~#

# mac address zenin
# ===========================================================
zenin:~# ip link show eth0
63843: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:43:f9:6b:00 brd ff:ff:ff:ff:ff:ff
zenin:~#

# mac address okkotsu
# ===========================================================
okkotsu:~# ip link show eth0
63851: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether 02:42:7a:09:9a:00 brd ff:ff:ff:ff:ff:ff
okkotsu:~#

# ringkasan dari hasil mac address masing-masing node
# ===========================================================
# MAC itadori = 02:42:47:97:d1:00
# MAC fushiguro = 02:42:bb:96:e3:00
# MAC zenin = 02:42:43:f9:6b:00
# MAC okkotsu = 02:42:7a:09:9a:00

# tengen
# ===========================================================

# buat skrip soal-04.sh
# ===========================================================
nano /root/soal-04.sh

# isi file soal-04.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 4 - Setup DHCP Class Pool Network 2 (tengen)
# Kelompok: K44 | Prefix: 192.233
# ========================================================

cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

# Class Pool 1 (Tim Dev: itadori & fushiguro)
class "pool1_dev" {
    match if (
        substring(hardware, 1, 6) = 02:42:47:97:d1:00 or
        substring(hardware, 1, 6) = 02:42:bb:96:e3:00
    );
}

# Class Pool 2 (Tim Support: zenin & okkotsu)
class "pool2_support" {
    match if (
        substring(hardware, 1, 6) = 02:42:43:f9:6b:00 or
        substring(hardware, 1, 6) = 02:42:7a:09:9a:00
    );
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

    # Pool 1: 192.233.2.10 - 192.233.2.35
    pool {
        allow members of "pool1_dev";
        range 192.233.2.10 192.233.2.35;
    }

    # Pool 2: 192.233.2.70 - 192.233.2.95
    pool {
        allow members of "pool2_support";
        range 192.233.2.70 192.233.2.95;
    }
}

# Subnet Network 3 (Divisi B)
subnet 192.233.3.0 netmask 255.255.255.0 {
    option routers 192.233.3.1;
    option broadcast-address 192.233.3.255;
}
EOF

# Validasi & Restart
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server restart

echo "[OK] DHCP Class Pool Soal 4 berhasil diperbarui di tengen."

# jalankan skrip soal-04.sh dan restart service DHCP Server
# ===========================================================
bash /root/soal-04.sh

# jalankan perintah berikut di semua client (itadori, fushiguro, zenin, okkotsu) untuk mendapatkan IP dari DHCP Server (tengen)
# ===========================================================
ifdown eth0 && ifup eth0
ip a

# ===========================================================
# interface
# ===========================================================

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