function vpn
    sudo openvpn --config ~/.config/openvpn/us-free-5.protonvpn.udp.ovpn --auth-user-pass ~/.config/openvpn/pass.txt --daemon
end
