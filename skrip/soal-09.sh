# Skrip lengkap soal 9

# ===========================================================
# terminal
# ===========================================================

# jichi
# ===========================================================
service isc-dhcp-relay stop

# itadori atau ino
# ===========================================================
ifdown eth0 && ifup eth0
# hasil nya adalah mencari broadcast bewrulang kali hingga menampilkan gagal dapet DHCP lease

# jichi
# ===========================================================
service isc-dhcp-relay start

# itadori atau ino
# ===========================================================
ifdown eth0 && ifup eth0
ip a
ip route