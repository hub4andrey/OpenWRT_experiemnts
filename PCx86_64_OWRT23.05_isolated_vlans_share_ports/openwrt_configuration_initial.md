# OpenWRT v23.05 on PC x86 64. Initial configuration

- [OpenWRT v23.05 on PC x86 64. Initial configuration](#openwrt-v2305-on-pc-x86-64-initial-configuration)
	- [initial configuration. From GUI](#initial-configuration-from-gui)
		- [Network -\> Interfaces](#network---interfaces)
		- [Network -\> Firewall](#network---firewall)
	- [initial configuration. From CLI](#initial-configuration-from-cli)

## initial configuration. From GUI


### Network -> Interfaces

Interfaces:

![img](./imgs/openwrt_initial_configuration_v23.05_001.png)

Devices:

![img](./imgs/openwrt_initial_configuration_v23.05_002.png)

Global network options:

![img](./imgs/openwrt_initial_configuration_v23.05_003.png)



### Network -> Firewall

General settings:

![img](./imgs/openwrt_initial_configuration_v23.05_004.png)



## initial configuration. From CLI

```bash
# ============================
# get hardware and OS basic info
# ============================
ubus call system board
{
	"kernel": "5.15.150",
	"hostname": "OpenWrt",
	"system": "Intel(R) Atom(TM) CPU C3758R @ 2.40GHz",
	"model": "Default string XXXXXX",
	"board_name": "default-string-XXXXXX",
	"rootfs_type": "ext4",
	"release": {
		"distribution": "OpenWrt",
		"version": "23.05.3",
		"revision": "r23809-234f1a2efa",
		"target": "x86/64",
		"description": "OpenWrt 23.05.3 r23809-234f1a2efa"
	}
}


# ============================
# get network config
# ============================
uci export network
package network

config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config globals 'globals'
	option ula_prefix 'xxxx:xxxx:xxxx::/48'

config device
	option name 'br-lan'
	option type 'bridge'
	option ipv6 '0'
	list ports 'eth4'
	list ports 'eth5'
	list ports 'eth6'
	list ports 'eth7'

config interface 'lan'
	option device 'br-lan'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'
	option ip6assign '60'

config interface 'wan'
	option device 'eth8'
	option proto 'dhcp'

config interface 'wan6'
	option device 'eth8'
	option proto 'dhcpv6'


# ============================
# get DHCP config
# ============================
uci export dhcp
package dhcp

config dnsmasq
	option domainneeded '1'
	option boguspriv '1'
	option filterwin2k '0'
	option localise_queries '1'
	option rebind_protection '1'
	option rebind_localhost '1'
	option local '/lan/'
	option domain 'lan'
	option expandhosts '1'
	option nonegcache '0'
	option cachesize '1000'
	option authoritative '1'
	option readethers '1'
	option leasefile '/tmp/dhcp.leases'
	option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
	option nonwildcard '1'
	option localservice '1'
	option ednspacket_max '1232'
	option filter_aaaa '0'
	option filter_a '0'

config dhcp 'lan'
	option interface 'lan'
	option start '100'
	option limit '150'
	option leasetime '12h'
	option dhcpv4 'server'
	option dhcpv6 'server'
	option ra 'server'
	option ra_slaac '1'
	list ra_flags 'managed-config'
	list ra_flags 'other-config'

config dhcp 'wan'
	option interface 'wan'
	option ignore '1'


# ============================
# get firewall config
# ============================
uci export firewall
package firewall

config defaults
	option syn_flood '1'
	option input 'REJECT'
	option output 'ACCEPT'
	option forward 'REJECT'

config zone
	option name 'lan'
	list network 'lan'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'

config zone
	option name 'wan'
	list network 'wan'
	list network 'wan6'
	option input 'REJECT'
	option output 'ACCEPT'
	option forward 'REJECT'
	option masq '1'
	option mtu_fix '1'

config forwarding
	option src 'lan'
	option dest 'wan'

config rule
	option name 'Allow-DHCP-Renew'
	option src 'wan'
	option proto 'udp'
	option dest_port '68'
	option target 'ACCEPT'
	option family 'ipv4'

config rule
	option name 'Allow-Ping'
	option src 'wan'
	option proto 'icmp'
	option icmp_type 'echo-request'
	option family 'ipv4'
	option target 'ACCEPT'

config rule
	option name 'Allow-IGMP'
	option src 'wan'
	option proto 'igmp'
	option family 'ipv4'
	option target 'ACCEPT'

config rule
	option name 'Allow-DHCPv6'
	option src 'wan'
	option proto 'udp'
	option dest_port '546'
	option family 'ipv6'
	option target 'ACCEPT'

config rule
	option name 'Allow-MLD'
	option src 'wan'
	option proto 'icmp'
	option src_ip 'xxxx::/10'
	list icmp_type '130/0'
	list icmp_type '131/0'
	list icmp_type '132/0'
	list icmp_type '143/0'
	option family 'ipv6'
	option target 'ACCEPT'

config rule
	option name 'Allow-ICMPv6-Input'
	option src 'wan'
	option proto 'icmp'
	list icmp_type 'echo-request'
	list icmp_type 'echo-reply'
	list icmp_type 'destination-unreachable'
	list icmp_type 'packet-too-big'
	list icmp_type 'time-exceeded'
	list icmp_type 'bad-header'
	list icmp_type 'unknown-header-type'
	list icmp_type 'router-solicitation'
	list icmp_type 'neighbour-solicitation'
	list icmp_type 'router-advertisement'
	list icmp_type 'neighbour-advertisement'
	option limit '1000/sec'
	option family 'ipv6'
	option target 'ACCEPT'

config rule
	option name 'Allow-ICMPv6-Forward'
	option src 'wan'
	option dest '*'
	option proto 'icmp'
	list icmp_type 'echo-request'
	list icmp_type 'echo-reply'
	list icmp_type 'destination-unreachable'
	list icmp_type 'packet-too-big'
	list icmp_type 'time-exceeded'
	list icmp_type 'bad-header'
	list icmp_type 'unknown-header-type'
	option limit '1000/sec'
	option family 'ipv6'
	option target 'ACCEPT'

config rule
	option name 'Allow-IPSec-ESP'
	option src 'wan'
	option dest 'lan'
	option proto 'esp'
	option target 'ACCEPT'

config rule
	option name 'Allow-ISAKMP'
	option src 'wan'
	option dest 'lan'
	option dest_port '500'
	option proto 'udp'
	option target 'ACCEPT'


# ============================
# get WiFi config
# ============================
uci export wireless
uci: Entry not found
# yes, I'm on PC x86_64 without WiFi module.
```
