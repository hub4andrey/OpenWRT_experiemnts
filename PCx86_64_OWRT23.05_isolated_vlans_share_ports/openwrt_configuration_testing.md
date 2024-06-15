# Add VLANs. Run tests

TOC:

- [Add VLANs. Run tests](#add-vlans-run-tests)
  - [Add VLANs temporally, test communication between subnets and router](#add-vlans-temporally-test-communication-between-subnets-and-router)
  - [Monitoring traffic on OpenWRT interfaces](#monitoring-traffic-on-openwrt-interfaces)
  - [Flush PC IP address and ARP table content](#flush-pc-ip-address-and-arp-table-content)
  - [How to add VLANs permanently with Netplan](#how-to-add-vlans-permanently-with-netplan)
    - [README](#readme)
    - [add configuration](#add-configuration)
    - [apply configuration](#apply-configuration)

## Add VLANs temporally, test communication between subnets and router

for real test it's good to connect two PCs to OpenWRT router ports: one PC to port `eth6`, another one - to port `eth7`. Then to configure both PCs the same. Then test connections between these two PCs on different sub-nets/VLANs.

Keep in mind that VLAN 101 (`dev` sub-net) is not available on OpenWRT router port `eth7`. The same: VLAN 102 (`stg` sub-net) is not available on OpenWRT router port `eth6`. I.e. PC will not get IP address for one of VLANs depend on which OpenWRT port we connect this PC to.

On our test PC I have 3 network adaptors. We will use `enp0s25` adaptor.

```bash
# ================================
# PC 1.  
# what are my network adaptors ?
# ================================
ip link

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether xx:xx:xx:xx:x:bb brd ff:ff:ff:ff:ff:ff
3: enx000123456789: ...
4: wlan0: ...

# OK, enp0s25 is our network adaptor with RJ45 interface

# ================================
# PC 1. (temporally) add VLAN link 
# Note: use "netplan" for permanent config
# ================================
ip link add link enp0s25 name enp0s25.101 type vlan id 101
ip link add link enp0s25 name enp0s25.102 type vlan id 102
ip link add link enp0s25 name enp0s25.103 type vlan id 103
ip link add link enp0s25 name enp0s25.104 type vlan id 104

# ================================
# PC 1. Set link UP
# ================================
ip link set enp0s25.101 up
ip link set enp0s25.102 up
ip link set enp0s25.103 up
ip link set enp0s25.104 up

# down WiFi link:
ip link set dev wlan0 down


# ================================
# PC 1. Request OpenWRT to assign IP address to given interface
# ================================
# -d: force  dhclient to run as a foreground process.
# -nw: become a daemon immediately (nowait) rather than waiting until an IP address has been acquired.
dhclient -d -nw enp0s25
dhclient -d -nw enp0s25.101
dhclient -d -nw enp0s25.102
dhclient -d -nw enp0s25.103
dhclient -d -nw enp0s25.104


# ================================
# PC 2. Repeat all above steps for PC 2.
# ================================



# ================================
# PC 1. Scan refresh ARP records, get protocol addresses
# ================================
# find all neighbors on OSI L2 level  (MAC addresses)
arp-scan --interface=enp0s25     --localnet
arp-scan --interface=enp0s25.101 --localnet
arp-scan --interface=enp0s25.102 --localnet
arp-scan --interface=enp0s25.103 --localnet
arp-scan --interface=enp0s25.104 --localnet


# If for some reason you can not obtain IPv4 address for particular interface
# we can "pretend" that we have valid IP address and send broadcast requests:
arp-scan --interface=enp0s25.101 --arpspa=192.168.101.123 192.168.101.0/24
arp-scan --interface=enp0s25.102 --arpspa=192.168.102.123 192.168.102.0/24
arp-scan --interface=enp0s25.103 --arpspa=192.168.103.123 192.168.103.0/24
arp-scan --interface=enp0s25.104 --arpspa=192.168.104.123 192.168.104.0/24

# Who are our neighbors? get all collected ARP records:
ip neigh show all


# ================================
# PC 1. Ping neighbors to test communication between sub-nets
# ================================
# -c count: stop after sending count ECHO_REQUEST packets.
# -I interface: interface is either an address, an interface name or a VRF name.
ping -c 3 -I enp0s25      192.168.99.ip_PC2
ping -c 3 -I enp0s25.101 192.168.101.ip_PC2
ping -c 3 -I enp0s25.102 192.168.102.ip_PC2
ping -c 3 -I enp0s25.103 192.168.103.ip_PC2
ping -c 3 -I enp0s25.104 192.168.104.ip_PC2


# ================================
# Trace routing
# ================================

# Within the same sub-net
#
# Trace connection in the same sub-net between PC 1 and PC 2.
# This communication going through bridge "brm103", not reaching firewall.
# To monitor the traffic run `tcpdump -ne -i brm103` in router terminal.
# You are in PC 1 terminal. Run:
traceroute --interface=enp0s25.103 192.168.103.ip_PC2

# Between different sub-nets
#
# If we modify firewall "fw_stg", by adding 'fw_dev' into "allow forward from zones", then we can call PC 2 IP 192.168.102.ip_PC2 from interface enp0s25.101 on PC 1
# This communication going through router firewall. Before packets from VLANs 101 and 102 reach firewall, they are isolated from each other.
# To monitor the traffic between PC 1 and router firewall run `tcpdump -ne -i brr101` in router terminal.
# To monitor the traffic between PC 2 and router firewall run `tcpdump -ne -i brl102` in router terminal.
# You are in PC 1 terminal. Run:
traceroute --interface=enp0s25.101 192.168.102.ip_PC2
```


## Monitoring traffic on OpenWRT interfaces

```bash
# Get list all interfaces we can monitor:
ip link

# tcpdump options:
# -n: don't convert addresses (i.e., host addresses, port numbers, etc.) to names.
# -e: print the link-level header on each dump line.
# -i interface, --interface=interface

# Monitor traffic passing through physical adaptor eth7:
tcpdump -ne -i eth7

# Monitor traffic passing through VLAN on eth7:
tcpdump -ne -i eth7.103

# Monitor traffic passing through bridge that bind eth6.103 and eth7.103
tcpdump -ne -i brm103

```

## Flush PC IP address and ARP table content

If you want to make new set of experiments, flush IP addresses received from OpenWRT router and MAC addresses of other devices visible from our test PC.

```bash
# ================================
# PC 1. flush IP addresses on all interfaces
# ================================
ip addr flush dev enp0s25
ip addr flush dev enp0s25.101
ip addr flush dev enp0s25.102
ip addr flush dev enp0s25.103
ip addr flush dev enp0s25.104

# I do flushing entries in neighbor table (ARP) 
# on all interfaces as well:
ip neigh flush all

# Now our PC1 is again "fresh unboxed device" with configured VLANs, ready for testing our network
```


## How to add VLANs permanently with Netplan

### README

- [Netplan (Canonical) documentation](https://netplan.readthedocs.io/en/latest/)
  - [YAML configuration](https://netplan.readthedocs.io/en/latest/netplan-yaml/)
  - [Netplan frequently asked questions](https://netplan.io/faq)
  - [GitHub. docs and examples](https://github.com/canonical/netplan/tree/main/examples)

### add configuration

```bash
cat /etc/netplan/10-add-my-vlans.yaml 
network:
    version: 2

    ethernets:
      enp0s25:
        dhcp4: no
        dhcp6: no

    vlans:
      enp0s25.101:
        id: 101
        link: enp0s25
        dhcp4: yes

      enp0s25.102:
        id: 102
        link: enp0s25
        dhcp4: yes

      enp0s25.103:
        id: 103
        link: enp0s25
        dhcp4: yes

      enp0s25.104:
        id: 104
        link: enp0s25
        dhcp4: yes


```

### apply configuration

```bash
# parse and write config to the disk, apply on next boot
sudo netplan generate

# parse and apply configuration to system immediatelly:
sudo netplan apply
```