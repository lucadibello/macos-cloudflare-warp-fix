# Zero Trust - Access LAN via Zero Trust Network

This script is utilized to resolve routing issues within the Zero Trust Network, enabling connections to a server on the LAN via the Zero Trust network rather than via the local interface.

> Note: this script depends on MacOS specific commands and may not work on other operating systems.

## Prerequisites

- Working Cloudflare Zero Trust network
- Override the Cloudflare WARP local interface IP address to use a CGNAT IP address (view setting [here](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/warp-settings/#override-local-interface-ip))
