# Project goals

1. Interface "dev" (development) = VLAN 101 goes to ethernet port 6 only; DHCP: static, xxx.xxx.xxx..1/24
2. Interface "stg" (stage) = VLAN 102 goes to ethernet port 7 only; DHCP: static, xxx.xxx.xxx..1/24
3. Interface "prod" = VLAN 103 goes to both ethernet ports 6 & 7; DHCP: static, xxx.xxx.xxx..1/24
4. Interface "IoT" = VLAN 104 goes to both ethernet ports 6 & 7; DHCP: static, xxx.xxx.xxx..1/24
5. Interface "LAN" = NO VLAN (untagged) goes to both ethernet ports 4 & 5; DHCP: static, 192.168.1.1/24
6. Interface "net plug" = NO VLAN (untagged) goes to to both ethernet ports 6 & 7; DHCP: static, 192.168.99.1/24. This is default interfaces for all devices who are not aware about existing VLANs.
7. VLANs are isolated
8. Zone "fw_dev" (firewall for "dev")
   1. development environment, soft rules that allow most connections. Dev can access Internet.
   2. covered networks/interfaces: "dev"
   3. INPUT (to all router services): allow
   4. OUTPUT (from router services to zone): allow
   5. FORWARD (between covered networks/interfaces): disable
   6. allow forward from zones: "lan"
   7. allow forward to zones: "wan", "wan6"
   8. extra traffic rules: non
9. Zone "fw_stg" (firewall for "stg")
   1. staging environment, more strict rules that allow some connections. Stage can access Internet.
   2. covered networks/interfaces: "stg"
   3. INPUT (to all router services): disable
   4. OUTPUT (from router services to zone): allow
   5. FORWARD (between covered networks/interfaces): disable
   6. allow forward from zones: "lan"
   7. allow forward to zones: "wan", "wan6"
   8. extra traffic rules:
      1. from zone "fw_stg" to router ports 53 67 68 by TCP UDP: allow
10. Zone "fw_prod" (firewall for "prod")
   1. production environment, most strict rules that disable connection from prod or to prod subnet. Prod can access Internet.
   2. covered networks/interfaces: "prod"
   3. INPUT (to all router services): disable
   4. OUTPUT (from router services to zone): allow
   5. FORWARD (between covered networks/interfaces): disable
   6. allow forward from zones: non
   7. allow forward to zones: "wan", "wan6"
   8. extra traffic rules:
      1. from zone "fw_prod" to router ports 53 67 68 by TCP UDP: allow
11. Zone "fw_iot" (firewall for "IoT")
   1. subnet for IoT. "lan" users can request IoT. IoT can't access Internet.
   2. covered networks/interfaces: "iot"
   3. INPUT (to all router services): disable
   4. OUTPUT (from router services to zone): allow
   5. FORWARD (between covered networks/interfaces): disable
   6. allow forward from zones: "lan"
   7. allow forward to zones: non
   8. extra traffic rules:
      1. from zone "fw_iot" to router ports 53 67 68 by TCP UDP: allow
12. Zone "fw_netplug" (firewall for "net plug")
   1. Any host landed into "net plug" is not allowed to communicate with other subnets, including Internet.
   2. covered networks/interfaces: "net plug"
   3. INPUT (to all router services): disable
   4. OUTPUT (from router services to zone): allow
   5. FORWARD (between covered networks/interfaces): disable
   6. allow forward from zones: non
   7. allow forward to zones: non
   8. extra traffic rules:
      1. from zone "fw_netplug" to router ports 53 67 68 by TCP UDP: allow
