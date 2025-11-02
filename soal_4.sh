# Node Erendis (DNS Master)

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




# Node Amdir (DNS Slave)

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
