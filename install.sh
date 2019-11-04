#!/bin/bash

sudo apt-get remove -y docker docker-engine docker.io containerd runc

sudo add-apt-repository -y ppa:wireguard/wireguard
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update -y

sudo apt-get install -y \
    apt-transport-https ca-certificates curl gnupg-agent software-properties-common \
    wireguard \
    docker-ce docker-ce-cli containerd.io docker-compose

apt-get remove -y dnsmasq
echo "nameserver 1.1.1.1" >/etc/resolv.conf

modprobe wireguard
modprobe iptable_nat
modprobe ip6table_nat

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.conf   
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf    



read -p "please input ssr server ip:" ssr_server_ip
read -p "please input ssr server port begin:" ssr_server_port_begin
read -p "please input ssr server port end:" ssr_server_port_end

read -p "please input ssr web domain:" ignite_domain
read -p "please input ssr manage web domain:" ignite_admin_domain
read -p "please input ssr admin name:" ignite_admin_name
read -p "please input ssr admin password:" ignite_admin_pwd
read -p "please input ssr auth secret:" ignite_admin_auth_secret
read -p "please input wireguard manage web domain:" subspace_domain

sudo mkdir -p /ladder/ssr/
sudo mkdir -p /ladder/wireguard/

sudo cat > /ladder/ssr/docker-compose.yml <<-EOF
version: '2'
services:
    nginx-proxy:
        container_name: nginx-proxy
        image: jwilder/nginx-proxy
        ports:
            - "80:80"
        volumes:
            - /var/run/docker.sock:/tmp/docker.sock:ro
        restart: always
    ignite:
        container_name: ignite
        image: goignite/ignite
        volumes:
            - "/ladder/ssr/data:/root/ignite/data"
            - "/var/run/docker.sock:/var/run/docker.sock"
        environment:
            - HOST_ADDRESS=$ssr_server_ip
            - HOST_FROM=$ssr_server_port_begin
            - HOST_TO=$ssr_server_port_end
            - VIRTUAL_PORT=9000
            - VIRTUAL_HOST=$ignite_domain
        restart: always
    ignite-admin:
        container_name: ignite-admin
        image: goignite/ignite-admin
        volumes:
            - "/ladder/ssr/data:/root/ignite/data"
            - "/var/run/docker.sock:/var/run/docker.sock"
        environment:
            - AUTH_USERNAME=$ignite_admin_name
            - AUTH_PASSWORD=$ignite_admin_pwd
            - Auth_SECRET=$ignite_admin_auth_secret
            - VIRTUAL_PORT=8000
            - VIRTUAL_HOST=$ignite_admin_domain
        restart: always
EOF


sudo systemctl enable docker
sudo systemctl start docker

docker create \
--name subspace \
--network host \
--cap-add NET_ADMIN \
--volume /usr/bin/wg:/usr/bin/wg \
--volume /ladder/wireguard/data:/data \
--env SUBSPACE_HTTP_HOST=$subspace_domain \
    subspacecloud/subspace:latest

sudo cat > /etc/init.d/wgweb-start <<-EOF
#! /bin/bash
### BEGIN INIT INFO
# Provides:		wgweb-start
# Required-Start:	$remote_fs $syslog
# Required-Stop:    $remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	wgweb-start
### END INIT INFO

sudo docker-compose -f /ladder/ssr/docker-compose.yml down

modprobe wireguard
modprobe iptable_nat
modprobe ip6table_nat
sudo docker start subspace

EOF

sudo chmod 755 /etc/init.d/wgweb-start
sudo update-rc.d wgweb-start defaults



sudo cat > /etc/init.d/ssrweb-start <<-EOF
#! /bin/bash
### BEGIN INIT INFO
# Provides:		ssrweb-start
# Required-Start:	$remote_fs $syslog
# Required-Stop:    $remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	ssrweb-start
### END INIT INFO

sudo docker stop subspace

sudo docker-compose -f /ladder/ssr/docker-compose.yml up -d

EOF

sudo chmod 755 /etc/init.d/ssrweb-start
sudo update-rc.d ssrweb-start defaults

sudo systemctl enable wgweb-start.service
sudo systemctl enable ssrweb-start.service

sudo systemctl enable wg-quick@.service
sudo systemctl enable ssh.socket


