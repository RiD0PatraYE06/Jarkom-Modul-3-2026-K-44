# Skrip lengkap soal 3

# ===========================================================
# terminal
# ===========================================================

# jichi
# ===========================================================

# buat skrip soal-03.sh
# ===========================================================
nano /root/soal-03.sh

# isi file soal-03.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 3 - Setup DHCP Relay (jichi)
# Kelompok: K44 | Prefix: 192.233
# ========================================================

# 1. Update paket & Install isc-dhcp-relay
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay

# 2. Konfigurasi /etc/default/isc-dhcp-relay
# SERVERS: Alamat IP DHCP Server (tengen)
# INTERFACES: Interface client (eth2, eth3) + interface menuju server (eth4)
cat <<EOF > /etc/default/isc-dhcp-relay
SERVERS="192.233.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

# 3. Pastikan IP Forwarding tetap aktif
sysctl -w net.ipv4.ip_forward=1

# 4. Restart service DHCP Relay
service isc-dhcp-relay restart

echo "[OK] Setup DHCP Relay Soal 3 pada jichi selesai."

# bash manual
# ==========================================================
bash /root/soal-03.sh

# tes di node itadori dan ino
# ==========================================================
ifup eth0

# cek apakah mendapatkan IP dari DHCP Server (tengen)
# ==========================================================
ip a

# ===========================================================
# interface
# ===========================================================

# jichi
# ===========================================================
auto eth0
iface eth0 inet dhcp
	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

auto eth1
iface eth1 inet static
	address 192.233.1.1
	netmask 255.255.255.0

auto eth2
iface eth2 inet static
	address 192.233.2.1
	netmask 255.255.255.0

auto eth3
iface eth3 inet static
	address 192.233.3.1
	netmask 255.255.255.0

auto eth4
iface eth4 inet static
	address 192.233.4.1
	netmask 255.255.255.0

	up bash /root/soal-01.sh
	up bash /root/soal-03.sh