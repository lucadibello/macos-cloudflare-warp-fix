#!/bin/bash

# NOTICE: This is a MacOS specific script, and is not guaranteed to work on other OSs

# This script is utilized to resolve routing issues within the Zero Trust Network,
# enabling connections to a server on the LAN via the Zero Trust network rather
# than via the local interface.

# Check if the user has executed the script with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with root privileges. The script needs to alter the system routing table!"
    exit 1
fi

# Check if the user passed the local server IP as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <local_server_ip> [warp_interface_ip_range]"
    # Print also that if the user doesn't pass the WARP IP range, the default one will be used
    echo "  [!] If you don't pass the WARP IP range, the default one will be used: 100.96.0.0/12"
    exit 1
fi

# Validate whether the IP address is valid
if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address. Please provide a valid IP address."
    exit 1
fi

# Save argument into variable
LOCAL_SERVER_IP=$1
# Cloudflare WARP interface IP range (Carrier Grade NAT space, https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/warp-settings/#override-local-interface-ip)
WARP_IP_RANGE="100.96.0.0/12"
# Last IP in the WARP IP range
LAST_WARP_IP="100.111.255.255"

# Print settings
echo "Local server IP: $LOCAL_SERVER_IP"
echo "WARP IP range: $WARP_IP_RANGE"

# If user passed the WARP IP range as an argument, validate it and use it to override the default WARP IP range
if [ ! -z "$2" ]; then
    if [[ ! $2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        echo "Invalid WARP IP range. Please provide a valid CIDR IP range."
        exit 1
    fi
    WARP_IP_RANGE=$2
fi

# Function to convert IP address to integer
ip_to_int() {
  local IFS=.
  read ip1 ip2 ip3 ip4 <<< "$1"
  echo $((ip1 * 16777216 + ip2 * 65536 + ip3 * 256 + ip4))
}

# Function to convert integer back to IP address
int_to_ip() {
    local ip_int=$1
    echo "$((ip_int >> 24 & 255)).$((ip_int >> 16 & 255)).$((ip_int >> 8 & 255)).$((ip_int & 255))"
}

# Function to calculate the last IP address of a given range
calculate_last_ip() {
  local cidr=$1
  IFS='/' read -r ip mask <<< "$cidr"
  local ip_int=$(ip_to_int $ip)
  local wildcard=$((2**(32-mask)-1))
  local last_ip_int=$((ip_int | wildcard))
  echo $(int_to_ip $last_ip_int)
}

# Function to check if IP is in range
ip_in_range() {
  local ip=$(ip_to_int $1)
  local range_start=$(ip_to_int $2)
  local range_end=$(ip_to_int $3)

  if [[ $ip -ge $range_start && $ip -le $range_end ]]; then
    echo 1
  else
    echo 0
  fi
}

# Calculate start and end of the CGNAT range
range_start=$(echo $WARP_IP_RANGE | sed -e 's|/.*||') # Remove /12
range_end=$(calculate_last_ip $WARP_IP_RANGE)

# Print the calculated range
echo "Calculated WARP IP range: $range_start - $range_end"

# List all active interfaces and their IP addresses
INTERFACES=$(ifconfig | awk '/^[a-z]/ {intf=$1; sub(/:/, "", intf)} /inet / {print intf, $2}')

# Check each interface to see if it falls within the CGNAT range
while read -r line; do
    set -- $line
    intf=$1
    ip=$2

    # Check if IP is in range
    if [[ $(ip_in_range $ip $range_start $range_end) -eq 1 ]]; then
        echo "Interface $intf with IP $ip is within the Cloudflare WARP IP range."

        # Now, we can simply add add a static route to the server via the WARP interface
        # rather than using the local interface
        sudo route add -host $LOCAL_SERVER_IP -interface $intf

        # Check if the route was added successfully
        if [ $? -eq 0 ]; then
            echo "Route added successfully. You should now be able to connect to the server via the WARP interface."
            exit 0
        else
            echo "Failed to add route. Please try again."
            exit 1
        fi
    fi
done <<< "$INTERFACES"

echo ""
echo "[!] No interface found within the Cloudflare WARP IP range. Please ensure that the WARP interface is active and has an IP address within the range."
exit 1