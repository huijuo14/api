FROM feelingsurf/viewer:stable

# Install OpenVPN and dependencies
RUN apt-get update && apt-get install -y \
    openvpn \
    wget \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Download and use VPNGate public servers
CMD wget -O /tmp/vpn.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=156" && \
    openvpn --config /tmp/vpn.ovpn --daemon && \
    sleep 15 && \
    ./run.sh
