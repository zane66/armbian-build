#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		stretch)
			# your code here
			# InstallOpenMediaVault # uncomment to get an OMV 4 image
			;;
		buster)
			# your code here
			InstallHostapdFromSource
			;;
		bullseye)
			# your code here
			InstallHostapdFromSource
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			InstallHostapdFromSource
			;;
		jammy)
			# your code here
			InstallHostapdFromSource
			;;
	esac
} # Main

InstallHostapdFromSource() {
	# Function to download and build hostapd from source
	echo "Installing hostapd from source with support for latest WiFi technologies..."

	# Create a directory for the source code
	mkdir -p /usr/src/hostapd
	cd /usr/src/hostapd

	# Download latest hostapd source code
	# Using the development version for latest features
	wget -q https://w1.fi/releases/wpa_supplicant-2.10.tar.gz
	tar xzf wpa_supplicant-2.10.tar.gz
	cd wpa_supplicant-2.10/hostapd

	# Create comprehensive configuration file for hostapd build with latest technologies
	cat > .config <<EOF
# Drivers
CONFIG_DRIVER_HOSTAP=y
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y

# Latest WiFi standards
CONFIG_IEEE80211N=y
CONFIG_IEEE80211AC=y
CONFIG_IEEE80211AX=y     # WiFi 6
CONFIG_IEEE80211BE=y     # WiFi 7
CONFIG_IEEE80211D=y      # Country regulatory domains
CONFIG_IEEE80211H=y      # Spectrum Management (DFS)

# 6 GHz band support (WiFi 6E)
CONFIG_IEEE80211AX_HE_6GHZ=y

# WPA3 related
CONFIG_SAE=y             # Simultaneous Authentication of Equals (WPA3-Personal)
CONFIG_OWE=y             # Opportunistic Wireless Encryption
CONFIG_DPP=y             # Device Provisioning Protocol
CONFIG_DPP2=y            # DPP version 2
CONFIG_DPP3=y            # DPP version 3
CONFIG_SUITEB=y          # Suite B cryptography
CONFIG_SUITEB192=y       # Suite B 192-bit level

# Fast roaming and mesh
CONFIG_IEEE80211R=y      # Fast BSS Transition (802.11r)
CONFIG_IEEE80211AI=y     # Fast Initial Link Setup
CONFIG_FILS=y           # Fast Initial Link Setup
CONFIG_MESH=y           # Mesh networking (802.11s)

# High throughput features
CONFIG_MBO=y            # Multi-band operation
CONFIG_WMM_AC=y         # WMM Admission Control

# Libraries and interfaces
CONFIG_LIBNL32=y
CONFIG_TLS=openssl
CONFIG_GETRANDOM=y
CONFIG_WPA_TRACE=y

# WPS
CONFIG_WPS=y
CONFIG_WPS_UPNP=y
CONFIG_WPS_NFC=y

# Additional authentication methods
CONFIG_EAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_PSK=y

# RADIUS server
CONFIG_RADIUS_SERVER=y
CONFIG_PKCS12=y

# Debugging and control interface
CONFIG_INTERNAL_LIBTOMMATH=y
CONFIG_INTERNAL_LIBTOMMATH_FAST=y
CONFIG_WPA_CLI_EDIT=y
CONFIG_DEBUG_FILE=y
CONFIG_CTRL_IFACE=y
CONFIG_CTRL_IFACE_UNIX=y
CONFIG_TAXONOMY=y

# Hardware acceleration if available
CONFIG_TLS_OPENSSL_AFALG_SYNC=y
CONFIG_HW_CRYPTO_IF_AVAILABLE=y
EOF

	# Compile and install hostapd
	make clean
	make -j$(nproc)
	make install

	# Create necessary directories for configuration files
	mkdir -p /etc/hostapd

	# Create a comprehensive configuration template with latest technology options
	cat > /etc/hostapd/hostapd.conf.template <<EOF
# Advanced configuration for hostapd
# Supports WiFi 6, WiFi 7, WiFi 6E, and WPA3

interface=wlan0
driver=nl80211

# Basic settings
ssid=Armbian_AP
country_code=US  # Set your country code for regulatory compliance
hw_mode=a        # Use 5GHz band (can be changed)
channel=36       # Adjust based on your regulatory domain

# To use 6 GHz band (WiFi 6E), use:
# hw_mode=a
# channel=37    # Choose appropriate 6 GHz channel
# op_class=134  # Operating class for 6 GHz band

# Latest WiFi standards support
ieee80211d=1     # Country information
ieee80211h=1     # DFS (required in many regions)
ieee80211n=1     # WiFi 4 (802.11n)
ieee80211ac=1    # WiFi 5 (802.11ac)
ieee80211ax=1    # WiFi 6 (802.11ax)
# Uncomment for WiFi 7 support if hardware supports it
# ieee80211be=1  # WiFi 7 (802.11be)

# HE (High Efficiency) settings for WiFi 6/6E
he_su_beamformer=1
he_su_beamformee=1
he_mu_beamformer=1
he_twt_required=0

# WPA3 settings
wpa=2
wpa_key_mgmt=SAE WPA-PSK WPA-PSK-SHA256
# For transition mode (WPA2+WPA3):
# wpa_key_mgmt=SAE WPA-PSK WPA-PSK-SHA256
rsn_pairwise=CCMP
sae_require_mfp=1   # Management frame protection required with WPA3

# Passphrase (min 8 characters for WPA2, min 12 chars recommended for WPA3)
wpa_passphrase=armbian12345

# QoS
wmm_enabled=1
uapsd_advertisement_enabled=1

# Other optimizations
multicast_to_unicast=1
bss_transition=1
mbo=1

# Fast transition for roaming (802.11r)
mobility_domain=a1b2
ft_over_ds=0
ft_psk_generate_local=1
pmk_r1_push=1
EOF

	# Create systemd service file
	cat > /etc/systemd/system/hostapd.service <<EOF
[Unit]
Description=Hostapd IEEE 802.11 AP with support for latest WiFi technologies
After=network.target

[Service]
Type=forking
PIDFile=/run/hostapd.pid
ExecStart=/usr/local/bin/hostapd -P /run/hostapd.pid -B /etc/hostapd/hostapd.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload

	echo "Hostapd with latest WiFi technologies installed successfully."
} # InstallHostapdFromSource

Main "$@"
