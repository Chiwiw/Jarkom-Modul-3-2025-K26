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
