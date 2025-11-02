
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
