# Jarkom-Modul3-2025-K26

| No | Nama               | NRP      |
|----|----------------    |----------|
| 1  |Hanif Mawla Faizi   |5027241064|
| 2  |Fika Arka Nuriyah   |5027241071|

---

## Soal 1
Soal 1 mengharuskan kita membuat konfigurasi ip untuk masing masing node, untuk node Durin sebagai Router, konfigurasi nya seperti ini :
```sh
# Interface ke Internet (NAT)
auto eth0
iface eth0 inet dhcp

# Subnet 1 – Laravel Workers
auto eth1
iface eth1 inet static
    address 192.224.1.1
    netmask 255.255.255.0

# Subnet 2 – Clients
auto eth2
iface eth2 inet static
    address 192.224.2.1
    netmask 255.255.255.0

# Subnet 3 – DNS & DHCP
auto eth3
iface eth3 inet static
    address 192.224.3.1
    netmask 255.255.255.0

# Subnet 4 – Database & Forwarder
auto eth4
iface eth4 inet static
    address 192.224.4.1
    netmask 255.255.255.0

# Subnet 5 – PHP Workers
auto eth5
iface eth5 inet static
    address 192.224.5.1
    netmask 255.255.255.0

# Routing + NAT agar jaringan internal bisa akses Internet
up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE -s 192.224.0.0/16
up echo 1 > /proc/sys/net/ipv4/ip_forward
```


---

## Soal 2
Pada Node Aldarion, buat file ``setup-aldarion.sh`` di root :
```sh
nano /root/setup-aldarion.sh
```
Setelah itu isi file dengan konfigurasi berikut :
```sh

# Node Aldarion (DHCP server)

#!/bin/bash
# 🛠️ DHCP SERVER CONFIGURATION – Aldarion (Númenor)
# Prefix jaringan: 192.224

PREFIX="192.224"
INTERFACE="eth0"              # interface ke Durin
DNS_MASTER="${PREFIX}.3.2"    # Erendis (DNS Master)

echo "[1/4] Menulis konfigurasi DHCP..."
cat <<EOF > /etc/dhcp/dhcpd.conf
authoritative;
default-lease-time 600;
max-lease-time 7200;

# 👨 Keluarga Manusia (Subnet 1)
subnet ${PREFIX}.1.0 netmask 255.255.255.0 {
    range ${PREFIX}.1.6 ${PREFIX}.1.34;
    range ${PREFIX}.1.68 ${PREFIX}.1.94;
    option routers ${PREFIX}.1.1;
    option broadcast-address ${PREFIX}.1.255;
    option domain-name-servers ${DNS_MASTER};
}

# 🧝 Keluarga Peri (Subnet 2)
subnet ${PREFIX}.2.0 netmask 255.255.255.0 {
    range ${PREFIX}.2.35 ${PREFIX}.2.67;
    range ${PREFIX}.2.96 ${PREFIX}.2.121;
    option routers ${PREFIX}.2.1;
    option broadcast-address ${PREFIX}.2.255;
    option domain-name-servers ${DNS_MASTER};
}

# 🏰 Subnet 3 (DNS & Fixed IP)
subnet ${PREFIX}.3.0 netmask 255.255.255.0 {
    host khamul {
        hardware ethernet 02:42:d4:df:71:00;
        fixed-address ${PREFIX}.3.95;
    }
    option routers ${PREFIX}.3.1;
    option broadcast-address ${PREFIX}.3.255;
    option domain-name-servers ${DNS_MASTER};
}

# ⚙️ Subnet 4 (Database & Forwarder)
subnet ${PREFIX}.4.0 netmask 255.255.255.0 {
    option routers ${PREFIX}.4.1;
    option broadcast-address ${PREFIX}.4.255;
    option domain-name-servers ${PREFIX}.4.2;
}

# 🌉 Subnet penghubung relay
subnet ${PREFIX}.4.0 netmask 255.255.255.0 { }
EOF

echo "[2/4] Mengatur interface DHCP server..."
sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"${INTERFACE}\"/" /etc/default/isc-dhcp-server

echo "[3/4] Menyiapkan database lease..."
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases

echo "[4/4] Menjalankan DHCP server..."
pkill dhcpd
dhcpd -4 -f -d ${INTERFACE} &
sleep 2
echo "✅ DHCP Server Aldarion aktif dan melayani seluruh subnet Númenor."
```

Setelah itu kita pindah ke Node Durin dan bikin file ``setup-durin.sh`` :
```sh
nano /root/setup-aldarion.sh
```
Setelah itu isi file dengan konfigurasi berikut :
```sh
# Node Durin (DHCP relay)

#!/bin/bash
# 🔁 DHCP RELAY CONFIGURATION – Durin
# Prefix jaringan: 192.224

PREFIX="192.224"
DHCP_SERVER="${PREFIX}.4.4"   # IP Aldarion (DHCP Server)
INTERFACES="eth1 eth2 eth3 eth4 eth5"  # koneksi antar subnet

echo "[1/3] Menulis konfigurasi relay..."
cat <<EOF > /etc/default/isc-dhcp-relay
SERVERS="${DHCP_SERVER}"
INTERFACES="${INTERFACES}"
OPTIONS=""
EOF

echo "[2/3] Menjalankan DHCP relay daemon..."
dhcrelay -d ${DHCP_SERVER} ${INTERFACES} &
sleep 2

echo "[3/3] DHCP Relay Durin siap meneruskan permintaan ke ${DHCP_SERVER}"

```
Cara untuk tes :
1. Jalankan scritp dari Aldarion.
2. Jalankan scritp dari Durin.
3. Masuk ke Node dengan Dynamic IP dan cek ``ip a`` pada terminal.
  Dari Amandil :
  <img width="1082" height="216" alt="no2_bukti amandil" src="https://github.com/user-attachments/assets/0d89f7b7-ac6e-43d6-955f-b41e76250388" />

  Dari Gilgalad :
  <img width="1030" height="202" alt="no2_bukti gilgalad" src="https://github.com/user-attachments/assets/d4631f85-9ce4-402c-ac21-5cb448412c51" />


---

## Soal 3
Masuk ke Minastir dan buat file `setup-minastir.sh` :
```sh
nano /root/setup-minastir.sh
```
Isi file dengan script berikut :
```sh
#!/bin/bash
# ==========================================
# 🌐 Konfigurasi Minastir – DNS Forwarder Arda
# ==========================================
# Jaringan internal: 192.224.0.0/16
# Minastir terhubung ke Durin melalui eth0 (192.224.5.2)
# Gateway: 192.224.5.1 (Durin)
# Forward DNS eksternal: 192.168.122.1

FORWARD_DNS="192.168.122.1"
BIND_CONF="/etc/bind/named.conf.options"

echo "[1/5] Menulis konfigurasi BIND9..."
cat > $BIND_CONF <<EOF
options {
    directory "/var/cache/bind";

    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    listen-on { any; };
    recursion yes;
};

logging {
    channel query_log {
        file "/var/log/named_queries.log" versions 3 size 5m;
        severity info;
        print-time yes;
    };

    category queries { query_log; };
};


EOF

echo "[2/5] Memastikan resolv.conf menunjuk ke localhost..."
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo "[3/5] Mengaktifkan IP forwarding (jaga-jaga untuk akses routing kecil)..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
sysctl -p >/dev/null

echo "[4/5] Restart layanan BIND9..."
service bind9 restart
sleep 1

echo "[5/5] Tes resolusi DNS internal..."
apt install -y dnsutils >/dev/null 2>&1
service named restart

dig google.com @127.0.0.1 | grep "status\|SERVER"

echo "✅ Minastir aktif sebagai DNS Forwarder"
echo "   - IP: 192.224.5.2"
echo "   - Gateway: 192.224.5.1 (Durin)"
echo "   - Forwarders: ${FORWARD_DNS}"
```

Sekarang jalankan file tersebut dan kita masuk ke node lain, dan ubah resolver nya menjadi IP node Minastir.

Setelah itu, kita bisa coba ping google dan akan tetap bisa :
<img width="798" height="309" alt="no3_bukti dari anarion" src="https://github.com/user-attachments/assets/1b492dc6-f8c0-4a7c-aef0-61dc1ea5000c" />

Untuk log nya bisa dilihat dari Minastir :
<img width="1093" height="133" alt="no3_cek log minastir" src="https://github.com/user-attachments/assets/264c4515-9b75-4803-bd2d-cd9d798b3add" />



---

## Soal 4
Masuk ke Erendis (DNS Master) dan buat file `setup-erendis.sh` :
```sh
nano /root/setup-erendis.sh
```
isi file terbut dengan konfigurasi ini :
```sh
#!/bin/bash
# 👑 DNS MASTER CONFIGURATION – Erendis (ns1.k26.com)
DOMAIN="k26.com"
PREFIX="192.224"

echo "[1/6] Membuat direktori zona..."
mkdir -p /etc/bind/zones /run/named
chmod 775 /run/named

echo "[2/6] Menulis konfigurasi utama BIND (options)..."
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";

    // Dengarkan di semua interface IPv4
    listen-on port 53 { any; };
    listen-on-v6 { none; };

    // Izinkan query dari jaringan internal
    allow-query { ${PREFIX}.0.0/16; };

    recursion yes;
    allow-transfer { ${PREFIX}.3.3; }; // Amdir (slave)
    forwarders { 192.168.122.1; };     // NAT host
};
EOF

echo "[3/6] Menulis konfigurasi zone master..."
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type master;
    file "/etc/bind/zones/db.${DOMAIN}";
    allow-transfer { ${PREFIX}.3.3; };
};
EOF

echo "[4/6] Menulis isi zone file..."
cat > /etc/bind/zones/db.${DOMAIN} <<EOF
\$TTL 604800
@   IN  SOA ns1.${DOMAIN}. admin.${DOMAIN}. (
        2025103101 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

@       IN  NS  ns1.${DOMAIN}.
@       IN  NS  ns2.${DOMAIN}.

; Nameserver
ns1         IN  A   ${PREFIX}.3.2
ns2         IN  A   ${PREFIX}.3.3

; DNS & Forwarder
erendis     IN  A   ${PREFIX}.3.2
amdir       IN  A   ${PREFIX}.3.3
minastir    IN  A   ${PREFIX}.5.2

; Beberapa host contoh
palantir    IN  A   ${PREFIX}.4.2
elros       IN  A   ${PREFIX}.1.2
pharazon    IN  A   ${PREFIX}.2.7
elendil     IN  A   ${PREFIX}.1.7
isildur     IN  A   ${PREFIX}.1.6
anarion     IN  A   ${PREFIX}.1.5
galadriel   IN  A   ${PREFIX}.2.5
celeborn    IN  A   ${PREFIX}.2.3
oropher     IN  A   ${PREFIX}.2.4
EOF

echo "[5/6] Validasi konfigurasi..."
named-checkconf
named-checkzone ${DOMAIN} /etc/bind/zones/db.${DOMAIN}

echo "[6/6] Restart layanan DNS..."
service named restart

echo "✅ Erendis (ns1.${DOMAIN}) aktif sebagai DNS Master!"
```

Setelah itu, masuk ke Amdir (DNS Slave) dan buat file `setup-amdir.sh` :
```sh
nano /root/setup-amdir.sh
```
isi file terbut dengan konfigurasi ini :
```sh
#!/bin/bash
# 🧩 DNS SLAVE CONFIGURATION – Amdir (ns2.k26.com)
DOMAIN="k26.com"
PREFIX="192.224"

echo "[1/5] Menyiapkan direktori zona & runtime..."
mkdir -p /etc/bind/zones /run/named
chmod 775 /run/named

echo "[2/5] Menulis named.conf.options..."
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";

    listen-on port 53 { any; };
    listen-on-v6 { none; };

    allow-query { ${PREFIX}.0.0/16; };
    recursion yes;
};
EOF

echo "[3/5] Menulis konfigurasi zone slave..."
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type slave;
    masters { ${PREFIX}.3.2; };  // Erendis (master)
    file "/etc/bind/zones/db.${DOMAIN}";
};
EOF

echo "[4/5] Validasi konfigurasi..."
named-checkconf

echo "[5/5] Restart layanan DNS..."
service named restart
echo "✅ Amdir (ns2.${DOMAIN}) aktif sebagai DNS Slave!"
```

Jalankan script DNS Master dan Slave.

Masuk ke Node Client lain dan coba kita cek :
- Cek elros.k26.com :
  <img width="751" height="419" alt="no4_cek elros k26 com" src="https://github.com/user-attachments/assets/84558e31-f815-40b8-98ce-62c10e5a8894" />

- Cek k26.com :
- <img width="1050" height="429" alt="no4_cek k26 com" src="https://github.com/user-attachments/assets/c47bd522-86cd-474e-85a7-93edd920e5fb" />



---

## Soal 5
Masuk ke Erendis (DNS Master) dan edit file `setup-erendis.sh` :
```sh
nano /root/setup-erendis.sh
```
isi file terbut dengan konfigurasi ini :
```sh
#!/bin/bash
# 👑 DNS MASTER CONFIGURATION – Erendis (ns1.k26.com)
DOMAIN="k26.com"
PREFIX="192.224"

echo "[1/7] Membuat direktori zona..."
mkdir -p /etc/bind/zones /run/named
chmod 775 /run/named

echo "[2/7] Menulis konfigurasi utama BIND (options)..."
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    listen-on-v6 { none; };
    allow-query { ${PREFIX}.0.0/16; };
    recursion yes;
    forwarders { 192.168.122.1; };
};
EOF

echo "[3/7] Menulis konfigurasi zone master..."
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type master;
    file "/etc/bind/zones/db.${DOMAIN}";
    allow-transfer { ${PREFIX}.3.3; }; // Amdir
};

zone "${PREFIX}.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.${PREFIX}.rev";
    allow-transfer { ${PREFIX}.3.3; };
};
EOF

echo "[4/7] File zone utama (${DOMAIN})..."
cat > /etc/bind/zones/db.${DOMAIN} <<EOF
\$TTL 604800
@   IN  SOA ns1.${DOMAIN}. admin.${DOMAIN}. (
        2025103101 ; Serial
        604800     ; Refresh
        86400      ; Retry
        2419200    ; Expire
        604800 )   ; Negative Cache TTL

@       IN  NS  ns1.${DOMAIN}.
@       IN  NS  ns2.${DOMAIN}.

; === Nameservers ===
ns1         IN  A   ${PREFIX}.3.2
ns2         IN  A   ${PREFIX}.3.3

; === Host utama ===
erendis     IN  A   ${PREFIX}.3.2
amdir       IN  A   ${PREFIX}.3.3
minastir    IN  A   ${PREFIX}.5.2
palantir    IN  A   ${PREFIX}.4.2
elros       IN  A   ${PREFIX}.1.2
pharazon    IN  A   ${PREFIX}.2.7
elendil     IN  A   ${PREFIX}.1.7
isildur     IN  A   ${PREFIX}.1.6
anarion     IN  A   ${PREFIX}.1.5
galadriel   IN  A   ${PREFIX}.2.5
celeborn    IN  A   ${PREFIX}.2.3
oropher     IN  A   ${PREFIX}.2.4

; === Alias & TXT Record ===
www         IN  CNAME   ${DOMAIN}.
elros       IN  TXT     "Cincin Sauron"
pharazon    IN  TXT     "Aliansi Terakhir"
EOF

echo "[5/7] Membuat reverse zone file..."
cat > /etc/bind/zones/db.${PREFIX}.rev <<EOF
\$TTL 604800
@   IN  SOA ns1.${DOMAIN}. admin.${DOMAIN}. (
        2025103101
        604800
        86400
        2419200
        604800 )

@   IN  NS  ns1.${DOMAIN}.
@   IN  NS  ns2.${DOMAIN}.

2.3     IN  PTR ns1.${DOMAIN}.
3.3     IN  PTR ns2.${DOMAIN}.
EOF

echo "[6/7] Validasi konfigurasi..."
named-checkconf
named-checkzone ${DOMAIN} /etc/bind/zones/db.${DOMAIN}
named-checkzone ${PREFIX}.in-addr.arpa /etc/bind/zones/db.${PREFIX}.rev

echo "[7/7] Restart layanan DNS..."
service named restart
echo "✅ Erendis (ns1.${DOMAIN}) aktif sebagai DNS Master!"
```

Masuk ke Amdir (DNS Slave) dan edit file `setup-amdir.sh` :
```sh
nano /root/setup-amdir.sh
```
isi file terbut dengan konfigurasi ini :
```sh
#!/bin/bash
# 🧩 DNS SLAVE CONFIGURATION – Amdir (ns2.k26.com)
DOMAIN="k26.com"
PREFIX="192.224"

echo "[1/5] Menyiapkan direktori zona & runtime..."
mkdir -p /etc/bind/zones /run/named
chmod 775 /run/named

echo "[2/5] Menulis named.conf.options..."
cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    listen-on-v6 { none; };
    allow-query { ${PREFIX}.0.0/16; };
    recursion yes;
};
EOF

echo "[3/5] Menulis konfigurasi zone slave..."
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type slave;
    masters { ${PREFIX}.3.2; };
    file "/etc/bind/zones/db.${DOMAIN}";
};

zone "${PREFIX}.in-addr.arpa" {
    type slave;
    masters { ${PREFIX}.3.2; };
    file "/etc/bind/zones/db.${PREFIX}.rev";
};
EOF

echo "[4/5] Validasi konfigurasi..."
named-checkconf

echo "[5/5] Restart layanan DNS..."
service named restart
echo "✅ Amdir (ns2.${DOMAIN}) aktif sebagai DNS Slave!"
```

Sekarang DNS sudah bisa Reverse PTR.

- Tes www.k26.com :
  <img width="755" height="458" alt="no5_ cek www k26" src="https://github.com/user-attachments/assets/435703c1-52eb-4f10-91d7-e6a726b35284" />
