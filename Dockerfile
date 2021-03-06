FROM alpine:3.13

RUN set -ex \
    && echo "http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk update \
    && apk upgrade \
    && apk add --no-cache \
    apache2-utils \
    bash \
    bcc-tools \
    bind-tools \
    bird \
    bpftrace-tools \
    bridge-utils \
    busybox-extras \
    conntrack-tools \
    coreutils \
    curl \
    dhcping \
    drill \
    ethtool \
    file \
    fping \
    git \
    htop \
    iftop \
    iperf \
    iproute2 \
    ipset \
    iptables \
    ip6tables \
    iptraf-ng \
    iputils \
    ipvsadm \
    ipython \
    jq \
    libc6-compat \
    liboping \
    moreutils \
    mtr \
    neofetch \
    net-snmp-tools \
    netcat-openbsd \
    nftables \
    ngrep \
    nmap \
    nmap-nping \
    openssl \
    pstree \
    py3-cryptography \
    py3-yaml \
    py3-virtualenv \
    python3 \
    scapy \
    socat \
    strace \
    su-exec \
    sudo \
    tcpdump \
    tcptraceroute \
    tini \
    tree \
    util-linux \
    vim \
    websocat \
    wireguard-tools

# Optimization for DNS lookup
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

# Installing ctop - top-like container monitor
RUN wget https://github.com/bcicen/ctop/releases/download/v0.7.5/ctop-0.7.5-linux-amd64 -O /usr/local/bin/ctop && chmod +x /usr/local/bin/ctop

# Installing calicoctl
ARG CALICOCTL_VERSION=v3.19.1
RUN set -exo pipefail; \
    wget https://github.com/projectcalico/calicoctl/releases/download/${CALICOCTL_VERSION}/calicoctl; \
    chmod +x calicoctl; \
    mv calicoctl /usr/local/bin

# Installing kubectl
ARG KUBECTL_VERSION=v1.21.1
RUN set -exo pipefail; \
    wget https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
    chmod +x kubectl; \
    mv kubectl /usr/local/bin;

# Installing K9s
ARG K9S_VERSION=v0.24.10
RUN set -exo pipefail; \
    curl -s -L https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${K9S_VERSION}_Linux_x86_64.tar.gz | \
        tar zxv k9s; \
    chmod +x k9s; \
    mv k9s /usr/local/bin;

# Settings
ADD motd /etc/motd
ADD profile  /etc/profile

CMD ["/bin/bash","-l"]
