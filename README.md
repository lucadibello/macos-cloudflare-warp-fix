# Zero Trust - Access LAN service from Zero Trust network

This script ensures secure and compliant access to local servers by enforcing all traffic to route through the Zero Trust network. It is specifically designed for environments where local servers are configured to reject any connections that do not originate from within a Zero Trust network framework. This approach enhances security by adhering to a Zero Trust model, where trust is never assumed based on network location.

> Note: This solution is tailored for MacOS and utilizes MacOS-specific commands. Compatibility with other operating systems has not been established.

This problem is known and also reported in the official Cloudflare Tunnel documentation: [*Connect private networks - router configuration*](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/private-net/cloudflared/#router-configuration).

## Objective

The main objective of this project is to overcome a prevalent issue within Zero Trust security models: ensuring that access to servers within the same local network (identical CIDR blocks) is securely managed and restricted to connections originating exclusively from the Zero Trust network.

To address this issue and facilitate access to these local servers through the Zero Trust network, I developed a MacOS system service that is able to recognize network configuration changes and, as soon as the user connects to the Zero Trust network via Cloudflare WARP, an automated script will create a new static routing configuration.

This patch will direct traffic through the Zero Trust network's virtual interface instead of the host's network interface card (NIC), which typically routes traffic directly over the local network.

## Prerequisites

- A functional Cloudflare Zero Trust network setup
- Valid ZeroTrust server configuration: the local server must be configured to accept connections only from the Zero Trust network. This may involve firewall rules, network policies, or specific server configurations designed to recognize and allow only Zero Trust network traffic.
- Static Cloudflare WARP local virtual interface subnet (i.e. CGNAT IP address, [view details](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/warp-settings/#override-local-interface-ip)
- MacOS device with administrator access to implement the necessary routing changes.

## Installation

First, clone the project:

```bash
git clone git@github.com:lucadibello/macos-zerotrust-lanmonitor.git
cd macos-zerotrust-lanmonitor
```

Then, build and install the system service on your system:

```bash
make install
```

Finally, to verify the correct installation and loading of the MacOS system service, please run the following command:

```bash
make verify
```

Done! You are now able to access local services via the ZeroTrust network without manually altering your routing table.

## Utility Makefile

This small project ships with a Makefile to perform various operations:

- `make build`: Builds the Swift service source code using `xcodebuild`.
- `make load`: Try to load the `com.lucadibello.zerotrust-lanmonitor` system service .
- `make unload`: Unloads the `com.lucadibello.zerotrust-lanmonitor` system service (stops it + remove it from the deamon list).
- `make install`: Builds from source the system service, creates the necessary files and assigns the right permissions, and load the new system service in the system.
- `make uninstall`: Unrolls all operations performed by the installation script (deleting files and service unloading).
- `make verify`: Verify if the service has been correctly installed in the system.

