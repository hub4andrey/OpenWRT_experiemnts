#!/usr/bin/bash

#======================================
#
# DESCRIPTION
#   This script collects configuration from OpenWRT OS v.23
#   and test PC1 on GNU Debian/Ubuntu
#
# IMPORTANT:
#   1st configure path to your project where you will store collected data.
#   Edit file router1_openwrt_collect_data_proj_dir.sh located in the same directory.
#
# SYNOPSIS
#   bash router1_openwrt_collected_data_sanitize.sh 
#
# OPTIONS
#
# COPYRIGHT
#   This is free software. There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


# I suppose, you have SSH connection to OpenWRT router.

source ./router1_openwrt_collect_data_proj_dir.sh

if [[ -z "${PROJDIR}" ]]; then
    echo -e "PROJDIR is missing: ${PROJDIR}.\nExiting"
    exit 1
fi


# ==========================
# Collect data from Router 1
# ==========================

USER_OPENWRT="root@192.168.1.1"
DEVICE_CONFIG_DIR="${PROJDIR}/config_router1_openwrt"


# Collect data from /etc dir:
mkdir --parents "${DEVICE_CONFIG_DIR}/etc"
cd "${DEVICE_CONFIG_DIR}/etc"

# Get OpenWRT configuration:
scp -r ${USER_OPENWRT}:/etc/config . 
# Remove history if any:
if [[ -d "${DEVICE_CONFIG_DIR}/etc/config/history" ]]; then
    rm -rf "${DEVICE_CONFIG_DIR}/etc/config/history"
fi

# Get kernel param at runtime:
scp -r "${USER_OPENWRT}:/etc/sysctl.d" .
scp "${USER_OPENWRT}:/etc/sysctl.conf" .



# Collect data from OpenWRT daemons:
cd "${DEVICE_CONFIG_DIR}"


# Get hardware and OS info
echo "# ssh ${USER_OPENWRT} ubus call system board > ubus_call_system_board" > ubus_call_system_board
ssh "${USER_OPENWRT}" ubus call system board >> ubus_call_system_board

# Get netowrk config, firewall, dhcp from ubus:
echo "# ssh ${USER_OPENWRT} ubus call uci get \'{\"config\": \"network\"}\'> ubus_call_uci_get_config_network" > ubus_call_uci_get_config_network
ssh "${USER_OPENWRT}" ubus call uci get \'{\"config\": \"network\"}\' >> ubus_call_uci_get_config_network

echo "# ssh ${USER_OPENWRT} ubus call uci get \'{\"config\": \"dhcp\"}\'> ubus_call_uci_get_config_dhcp" > ubus_call_uci_get_config_dhcp
ssh "${USER_OPENWRT}" ubus call uci get \'{\"config\": \"dhcp\"}\' >> ubus_call_uci_get_config_dhcp

echo "# ssh ${USER_OPENWRT} ubus call uci get \'{\"config\": \"firewall\"}\' > ubus_call_uci_get_config_firewall" > ubus_call_uci_get_config_firewall
ssh "${USER_OPENWRT}" ubus call uci get \'{\"config\": \"firewall\"}\' >> ubus_call_uci_get_config_firewall


# Get netowrk config, firewall, dhcp from uci:
echo "# ssh ${USER_OPENWRT} uci show network > uci_show_network" > uci_show_network
ssh "${USER_OPENWRT}" uci show network >> uci_show_network

echo "# ssh ${USER_OPENWRT} uci show dhcp > uci_show_dhcp" > uci_show_dhcp
ssh "${USER_OPENWRT}" uci show dhcp >> uci_show_dhcp

echo "# ssh ${USER_OPENWRT} uci show firewall > uci_show_firewall" > uci_show_firewall
ssh "${USER_OPENWRT}" uci show firewall >> uci_show_firewall


# Get network config from ip:
echo "# ssh ${USER_OPENWRT} ip -details -json link show \| jq > ip_details_json_link_show" > ip_details_json_link_show
ssh "${USER_OPENWRT}" ip -details -json link show \| jq >> ip_details_json_link_show

# Get network config from brctl:
echo "# ssh ${USER_OPENWRT} brctl show > brctl_show" > brctl_show
ssh "${USER_OPENWRT}" brctl show >> brctl_show

# showstp   	<bridge>		show bridge stp info:
echo "# ssh ${USER_OPENWRT} brctl showstp br-lan > brctl_br-lan_setup_show" > brctl_br-lan_setup_show
ssh "${USER_OPENWRT}" brctl showstp br-lan >> brctl_br-lan_setup_show

echo "# ssh ${USER_OPENWRT} brctl showstp brl102 > brctl_brl102_setup_show" > brctl_brl102_setup_show
ssh "${USER_OPENWRT}" brctl showstp brl102 >> brctl_brl102_setup_show

echo "# ssh ${USER_OPENWRT} brctl showstp brr101 > brctl_brr101_setup_show" > brctl_brr101_setup_show
ssh "${USER_OPENWRT}" brctl showstp brr101 >> brctl_brr101_setup_show

echo "# ssh ${USER_OPENWRT} brctl showstp brm103 > brctl_brm103_setup_show" > brctl_brm103_setup_show
ssh "${USER_OPENWRT}" brctl showstp brm103 >> brctl_brm103_setup_show

echo "# ssh ${USER_OPENWRT} brctl showstp brm104 > brctl_brm104_setup_show" > brctl_brm104_setup_show
ssh "${USER_OPENWRT}" brctl showstp brm104 >> brctl_brm104_setup_show

echo "# ssh ${USER_OPENWRT} brctl showstp br99 > brctl_br99_setup_show" > brctl_br99_setup_show
ssh "${USER_OPENWRT}" brctl showstp br99 >> brctl_br99_setup_show


# Get routing rules
echo "# ssh ${USER_OPENWRT} ip rout > ip_routing_table_show" > ip_routing_table_show
ssh "${USER_OPENWRT}" ip rout >> ip_routing_table_show
# Alternative mothod: netstat -r -n


# Get all network connections, routing tables, interface statistics
echo "${USER_OPENWRT} ss -tupl -n > ss_port_listeners_show" > ss_port_listeners_show
ssh "${USER_OPENWRT}" ss -tupl -n >> ss_port_listeners_show


echo "Information was collected from Router 1. Finishing"


# ==========================
# Collect data from PC1
# ==========================
USER_IP101_LAPTOP="whoareyou@192.168.101.128"
USER_IP103_LAPTOP="whoareyou@192.168.103.128"

DEVICE_CONFIG_DIR="${PROJDIR}/config_host1_laptop"


# Collect data from /etc dir:
mkdir --parents "${DEVICE_CONFIG_DIR}/etc"
cd "${DEVICE_CONFIG_DIR}/etc"

# copy NetPath config for VLANs
rsync -r --rsync-path="sudo rsync" ${USER_IP101_LAPTOP}:/etc/netplan .


# Collect data from PC1 daemons:
cd "${DEVICE_CONFIG_DIR}"
# Get network config from ip:
ssh "${USER_IP101_LAPTOP}" ip -details -json link show \| jq > ip_details_json_link_show
ssh "${USER_IP101_LAPTOP}" ip link > ip_link_show
ssh "${USER_IP101_LAPTOP}" ip addr > ip_addr_show


# Get network config from brctl:
echo "# ssh ${USER_IP101_LAPTOP} bridge link show > bridge_link_show" > bridge_link_show
ssh "${USER_IP101_LAPTOP}" sudo bridge link show >> bridge_link_show
echo "# ssh ${USER_IP101_LAPTOP} bridge vlan show > bridge_vlan_show" > bridge_vlan_show
ssh "${USER_IP101_LAPTOP}" sudo bridge vlan show >> bridge_vlan_show

# Get routing rules
echo "# ssh ${USER_IP101_LAPTOP} ip rout > ip_routing_table_show" > ip_routing_table_show
ssh "${USER_IP101_LAPTOP}" ip rout >> ip_routing_table_show


echo "Information was collected from PC1. Exiting."
exit 0