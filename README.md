# Laporan Praktikum Jarkom Modul 3

| Nama | NRP |
| --- | --- |
| Nayarfa Syamahira Dyananta | 5027251046 |
| Rido Patra Yudhistira Edwin | 5027251120 |

---

## Konfigurasi Semua Node
```bash
# ===========================================================
# main router
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

# ===========================================================
# network 1
# ===========================================================

# utahime
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.1.2
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# shoko
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.1.3
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# gojo
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.1.4
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# ===========================================================
# network 2
# ===========================================================

# itadori
# ===========================================================
auto eth0
iface eth0 inet dhcp

# fushiguro
# ===========================================================
auto eth0
iface eth0 inet dhcp

# zenin
# ===========================================================
auto eth0
iface eth0 inet dhcp

# okkotsu
# ===========================================================
auto eth0
iface eth0 inet dhcp

# ===========================================================
# network 3
# ===========================================================

# ino
# ===========================================================
auto eth0
iface eth0 inet dhcp

# kusakabe
# ===========================================================
auto eth0
iface eth0 inet dhcp

# kugisaki
# ===========================================================
auto eth0
iface eth0 inet dhcp

# miwa
# ===========================================================
auto eth0
iface eth0 inet dhcp

# ===========================================================
# network 4
# ===========================================================

# geto
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.2
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# maki
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.3
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# panda
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.4
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# nanami
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.5
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# todo
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.6
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# kirara
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.7
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# tengen
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.10
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

# yaga
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.8
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf


# inumaki
# ===========================================================
auto eth0
iface eth0 inet static
	address 192.233.4.9
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf

```

---

## Soal 1: Pemulihan Konektivitas Dasar, Routing, dan NAT pada Router Jichi

### Ringkasan Soal
Mengonfigurasi router utama `jichi` agar interface `eth0` memperoleh IP WAN dari NAT secara dinamis (DHCP), serta mengonfigurasi interface `eth1` hingga `eth4` sebagai gateway untuk Network 1–4 dengan prefix IP `192.233.x.x`. Mengaktifkan *IPv4 forwarding* dan *Source NAT (MASQUERADE)* pada router `jichi`, menetapkan IP statis untuk seluruh host infrastruktur pada Network 1 dan Network 4, serta membuktikan konektivitas host ke gateway dan jaringan luar/eksternal.

---

### Apa Saja yang Harus Kita Lakukan?
1. Mengonfigurasi file `/etc/network/interfaces` pada router `jichi` untuk interface `eth0` (DHCP WAN) serta interface `eth1`–`eth4` sebagai gateway subnet lokal (`192.233.1.1/24` hingga `192.233.4.1/24`).
2. Mengonfigurasi IP statis, default gateway mengarah ke `jichi`, dan DNS resolver pada seluruh host infrastruktur di Network 1 (`utahime`, `shoko`, `gojo`) serta Network 4 (`geto`, `maki`, `panda`, `nanami`, `todo`, `kirara`, `yaga`, `inumaki`, `tengen`).
3. Membuat skrip `/root/soal-01.sh` pada router `jichi` untuk mengaktifkan `net.ipv4.ip_forward=1` dan menambahkan aturan `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`.
4. Memanggil skrip secara otomatis lewat perintah `up bash /root/soal-01.sh` di bawah konfigurasi `auto eth4` pada `/etc/network/interfaces` router `jichi`.
5. Melakukan verifikasi konektivitas menggunakan perintah `ping` dari host infrastruktur menuju gateway router `jichi` (`192.233.1.1`) dan IP DNS eksternal (`8.8.8.8`).

---

### Skrip Apa Saja yang Kita Gunakan?

**1. Konfigurasi `/etc/network/interfaces` di Node Router `jichi`**

```bash
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
```

**2. Skrip Otomatisasi IP Forwarding & NAT di Router `jichi` (`/root/soal-01.sh`)**

```bash
#!/bin/bash

# 1. Mengaktifkan IP Forwarding di tingkat kernel Linux
sysctl -w net.ipv4.ip_forward=1

# 2. Membersihkan aturan NAT lama
iptables -t nat -F

# 3. Mengaktifkan MASQUERADE pada interface WAN (eth0 yang terhubung ke NAT)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

---

### Mekanisme Pengujian
Jalankan tes konektivitas berikut di terminal host infrastruktur (contoh pada `utahime` dan `tengen`):

```bash
# Ping ke IP gateway router jichi
ping -c 3 192.233.1.1

# Ping ke IP DNS eksternal / Google DNS untuk cek akses WAN/NAT
ping -c 3 8.8.8.8
```

---

### Hasil

![](./assets/01-tes-di-tengen.png)

*Gambar 1: Hasil pengujian ping dari node `tengen` ke gateway `192.233.1.1` dan IP publik `8.8.8.8` sukses dengan 0% packet loss.*

![](./assets/01-tes-di-utahime.png)

*Gambar 2: Hasil pengujian ping dari node `utahime` ke gateway `192.233.1.1` dan IP publik `8.8.8.8` sukses dengan 0% packet loss.*

---

## Soal 2: XXX

### Ringkasan Soal
Mengonfigurasi service `isc-dhcp-server` pada node Data Center `tengen` (`192.233.4.10`) untuk mengelola pengalokasian IP dinamis. Mendeklarasikan Network 4 (`192.233.4.0/24`) sebagai subnet lokal tanpa pool dinamis untuk mencegah munculnya error *"No subnet declaration for eth0"*, serta menyiapkan deklarasi *scope* DHCP untuk Network 2 (`192.233.2.0/24`) dan Network 3 (`192.233.3.0/24`). Memvalidasi sintaks konfigurasi dan memastikan service `isc-dhcp-server` berjalan dengan status aktif.

---

### Apa Saja yang Harus Kita Lakukan?
1. Menginstal paket `isc-dhcp-server` pada node `tengen`.
2. Mengonfigurasi file `/etc/default/isc-dhcp-server` agar *service* mendengarkan permintaan DHCP pada interface `eth0`.
3. Mengonfigurasi file `/etc/dhcp/dhcpd.conf` dengan mendeklarasikan subnet lokal Network 4 (`192.233.4.0/24`) tanpa pool dinamis, serta deklarasi *scope* subnet untuk Network 2 (`192.233.2.0/24`) dan Network 3 (`192.233.3.0/24`).
4. Membuat skrip otomatisasi `/root/soal-02.sh` pada node `tengen` untuk mengaplikasikan seluruh konfigurasi dan melakukan *restart service*.
5. Memanggil skrip otomatisasi melalui baris perintah `up bash /root/soal-02.sh` pada file `/etc/network/interfaces` di node `tengen`.
6. Memeriksa keabsahan sintaks konfigurasi menggunakan perintah `dhcpd -t` dan mengonfirmasi status service dengan perintah `service isc-dhcp-server status`.

---

### Skrip Apa Saja yang Kita Gunakan?
**1. Skrip Otomatisasi DHCP Server di Node `tengen` (`/root/soal-02.sh`)**

```bash
#!/bin/bash
# ========================================================
# Script Soal 2 - Setup DHCP Server Scope (tengen)
# Kelompok: K44 | Prefix: 192.233.x.x
# ========================================================

# 1. Update paket & Install isc-dhcp-server
apt-get update
apt-get install -y isc-dhcp-server

# 2. Atur interface tempat DHCP Server mendengarkan request (eth0)
cat <<EOF > /etc/default/isc-dhcp-server
INTERFACESv4="eth0"
INTERFACESv6=""
EOF

# 3. Konfigurasi /etc/dhcp/dhcpd.conf
cat <<EOF > /etc/dhcp/dhcpd.conf
# Global Configuration
authoritative;
default-lease-time 600;
max-lease-time 7200;

# A. Subnet Lokal Network 4 (Data Center) - TANPA POOL DINAMIS
# Wajib dideklarasikan agar tidak muncul error "No subnet declaration for eth0"
subnet 192.233.4.0 netmask 255.255.255.0 {
    option routers 192.233.4.1;
    option broadcast-address 192.233.4.255;
}

# B. Scope DHCP Network 2 (Divisi A)
subnet 192.233.2.0 netmask 255.255.255.0 {
    option routers 192.233.2.1;
    option broadcast-address 192.233.2.255;
}

# C. Scope DHCP Network 3 (Divisi B)
subnet 192.233.3.0 netmask 255.255.255.0 {
    option routers 192.233.3.1;
    option broadcast-address 192.233.3.255;
}
EOF

# 4. Validasi sintaks konfigurasi
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# 5. Restart dan aktifkan service isc-dhcp-server
service isc-dhcp-server restart

echo "[OK] Setup DHCP Server Soal 2 pada tengen selesai."
```

**2. Konfigurasi `/etc/network/interfaces` di Node `tengen`**

```bash
auto eth0
iface eth0 inet static
	address 192.233.4.10
	netmask 255.255.255.0
	gateway 192.233.1.1

	up echo "nameserver 192.168.122.1" > /etc/resolv.conf
	up bash /root/soal-02.sh
```

---

### Mekanisme Pengujian
Eksekusi perintah berikut pada terminal node **`tengen`**:

```bash
# Validasi sintaks file konfigurasi dhcpd.conf
dhcpd -t

# Verifikasi status operasional service isc-dhcp-server
service isc-dhcp-server status
```

---

### Hasil

![](./assets/02-hasil-verifikasi-tengen.png)

*Gambar 1: Hasil pengecekan sintaks `dhcpd -t` tanpa error dan verifikasi status service `isc-dhcp-server` yang menunjukkan `dhcpd is running` pada node `tengen`.*

---

## Soal 3: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 4: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 5: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 6: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 7: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 8: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 9: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---

## Soal 10: XXX

### Ringkasan Soal
xxx

---

### Apa Saja yang Harus Kita Lakukan?
1. xxx

---

### Skrip Apa Saja yang Kita Gunakan?
```bash

```

---

### Mekanisme Pengujian
```bash

```

---

### Hasil

![]()

---