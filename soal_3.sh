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
