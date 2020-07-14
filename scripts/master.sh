# Docker / Kubernetes Installation

# Clean up some old stuff on the install image
# Sleep is due to some initial tasks running after boot
sleep 20
sudo /usr/bin/rm -fv /etc/apt/sources.list.d/deb_debian_org_debian.list

# Docker Installation
sudo apt-get update
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    vim
curl -fSSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

# Kubernetes
echo br_netfilter | sudo tee -a /etc/modules
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Keepalived / HAProxy
# Install Keepalived and HAProxy
sudo apt-get -y install keepalived haproxy

# KeepAlived and HAProxy Global Variables
APISERVER_SRC_PORT="6443"
APISERVER_DEST_PORT="6443"
APISERVER_VIP="192.168.192.240"
INTERFACE=$(sudo route | grep '^default' | grep -o '[^ ]*$')
AUTH_PASS="42"

# Per Host Variables
if [[ $(hostname) = "k8s-master-0" ]]; then
  STATE="MASTER"
  ROUTER_ID="51"
  PRIORITY="100"
else
  STATE="BACKUP"
  ROUTER_ID="51"
  PRIORITY="101"
fi

# Keepalived Config
cat <<EOF | sudo tee /etc/keepalived/keepalived.conf
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
        ${APISERVER_VIP}
    }
    track_script {
        check_apiserver
    }
}
EOF

# Keepalived Health Check
cat <<EOF | sudo tee /etc/keepalived/check_apiserver.sh
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
EOF

sudo chmod 700 /etc/keepalived/check_apiserver.sh

# Setup Backend Hosts
array1=($(awk '{print $1}' /dev/shm/serverlist))
array2=($(awk '{print $2}' /dev/shm/serverlist))

for ((i=0;i<${#array1[@]};++i)); do
  sudo echo "        server ${array1[$i]} ${array2[$i]}:$APISERVER_SRC_PORT check" >> /dev/shm/haproxycfg
done

SERVER_BLOCK=$(cat /dev/shm/haproxycfg)
rm -fv /dev/shm/haproxycfg

# HAProxy Config
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
${SERVER_BLOCK}
EOF

# Enable Services
sudo systemctl enable haproxy --now
sudo systemctl enable keepalived --now
