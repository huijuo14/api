FROM feelingsurf/viewer:stable

ENV access_token="d6e659ba6b59c9866fba8ff01bc56e04"

# Download VPN config and run directly
CMD wget -q -O /tmp/vpn.ovpn "http://www.vpngate.net/common/openvpn_download.aspx?sid=156" && \
    [ -f /tmp/vpn.ovpn ] && \
    openvpn --config /tmp/vpn.ovpn --daemon && \
    sleep 25 && \
    ./run.sh || ./run.sh
