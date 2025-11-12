FROM feelingsurf/viewer:stable

# Use tools that are already available in the base image
# Most base images already have wget, curl

# Download and extract OpenVPN static binary (no apt required)
RUN wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.8.zip && \
    unzip openvpn-2.5.8.zip -d /tmp/openvpn/ && \
    cd /tmp/openvpn/openvpn-2.5.8 && \
    ./configure && make && make install

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Download VPN config and run
CMD wget -O /tmp/vpn.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=156" && \
    openvpn --config /tmp/vpn.ovpn --daemon && \
    sleep 20 && \
    ./run.sh
