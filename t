# 
client
proto tcp-client
dev tun
auth-user-pass
remote yourserver.domain 1194
ca ca.crt
cert client1.crt
key client1.key
tls-auth ta.key 1
remote-cert-tls server
auth-nocache
persist-tun
persist-key
compress lzo
verb 4
mute 10
