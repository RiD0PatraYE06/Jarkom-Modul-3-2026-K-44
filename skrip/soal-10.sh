# Skrip lengkap soal 9

# ===========================================================
# terminal
# ===========================================================

# jichi
# ===========================================================

# buat skrip soal-10.sh
# ===========================================================
nano /root/soal-10.sh

# isi file soal-10.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 10 - Autostart DHCP Relay (jichi)
# Kelompok: K44 | Prefix: 192.233
# ========================================================

# 1. Pastikan IP Forwarding aktif
sysctl -w net.ipv4.ip_forward=1

# 2. Restart & pastikan service berjalan
service isc-dhcp-relay restart

echo "[OK] Persistensi & Autostart DHCP Relay Soal 10 di jichi aktif."

# tengen
# ===========================================================

# buat skrip soal-10.sh
# ===========================================================
nano /root/soal-10.sh

# isi file soal-10.sh
# ===========================================================
#!/bin/bash
# ========================================================
# Script Soal 10 - Autostart DHCP Server (tengen)
# Kelompok: K44 | Prefix: 192.233
# ========================================================

# 1. Jalankan ulang konfigurasi kumulatif terakhir (Soal 7)
bash /root/soal-07.sh

# 2. Restart & pastikan service berjalan
service isc-dhcp-server restart

echo "[OK] Persistensi & Autostart DHCP Server Soal 10 di tengen aktif."

# verifikasi pasca reboot
# ===========================================================

# cek di jinchi
# ===========================================================
service isc-dhcp-relay status
ps aux | grep dhcrelay

# cek di tengen
# ===========================================================
service isc-dhcp-server status

# verifikasi ip dan lease 
# ===========================================================
ifdown eth0 && ifup eth0
ip a
ip route

# tes ping dari client ke tengen
# ===========================================================
ping -c 4 192.233.4.10

# ==========================================================
# interface
# ==========================================================

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
	up bash /root/soal-10.sh

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
	up bash /root/soal-10.sh