#############################
#     设置公共的变量         #
#############################
ARG BASE_IMAGE_TAG=resolute
FROM ubuntu:${BASE_IMAGE_TAG}

# 作者描述信息
LABEL org.opencontainers.image.authors="danxiaonuo" \
      org.opencontainers.image.vendor="danxiaonuo"
      
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/ubuntu
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=ubuntu
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=resolute
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# 环境设置
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=$DEBIAN_FRONTEND

# GO环境变量
ARG GO_VERSION=1.25.7
ENV GO_VERSION=$GO_VERSION
ARG GOROOT=/opt/go
ENV GOROOT=$GOROOT
ARG GOPATH=/opt/golang
ENV GOPATH=$GOPATH

# 安装依赖包
ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    conntrack \
    ipset \
    ipvsadm \
    bind9-dnsutils \
    iproute2 \
    net-tools \
    iptables \
    bridge-utils \
    openvswitch-switch \
    libseccomp2 \
    nfs-common \
    rsync \
    socat \
    psmisc \
    procps \
    sysstat \
    firewalld \
    chrony \
    ntpsec-ntpdate \
    tcpdump \
    telnet \
    lsof \
    iftop \
    htop \
    nmap \
    nmap-common \
    jq \
    curl \
    wget \
    axel \
    git \
    vim \
    tree \
    unzip \
    zip \
    tar \
    subversion \
    lrzsz \
    gcc \
    g++ \
    gcc-multilib \
    g++-multilib \
    build-essential \
    binutils \
    autoconf \
    automake \
    libtool \
    gettext \
    autopoint \
    asciidoc \
    gawk \
    patch \
    flex \
    texinfo \
    device-tree-compiler \
    zlib1g-dev \
    libc6-dev-i386 \
    libelf-dev \
    libssl-dev \
    openssl \
    libglib2.0-dev \
    xmlto \
    libncurses-dev \
    locate \
    lvm2 \
    rsyslog \
    ca-certificates \
    gnupg2 \
    debsums \
    locales \
    tzdata \
    fonts-droid-fallback \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    language-pack-zh-hans \
    numactl \
    xz-utils \
    libaio-dev \
    python3 \
    python3-dev \
    python3-pip \
    python3-yaml \
    python-is-python3 \
    tini \
    sshpass \
    iputils-ping \
    ncat \
    upx-ucl \
    uglifyjs"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i s@http://*.*ubuntu.com@https://mirrors.aliyun.com@g /etc/apt/sources.list && \
   sed -i 's?# deb-src?deb-src?g' /etc/apt/sources.list && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends $PKG_DEPS --option=Dpkg::Options::=--force-confdef && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   locale-gen zh_CN.UTF-8 && localedef -f UTF-8 -i zh_CN zh_CN.UTF-8 && locale-gen && \
   /bin/zsh

# ***** 升级 python3 版本 *****
RUN set -eux && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 1 && \
    pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple/ && \
    pip3 config set install.trusted-host mirrors.aliyun.com && \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py && \
    python3 /tmp/get-pip.py && rm -rf /tmp/get-pip.py && \
    pip3 install --upgrade pip setuptools wheel pycryptodome lxml cython beautifulsoup4 requests ansible passlib boto3 botocore docker docker-compose && \
    curl https://pyenv.run | bash && pyenv install 2.7.18 && pyenv global 2.7.18 && \
    wget --no-check-certificate https://bootstrap.pypa.io/pip/2.7/get-pip.py -O /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && rm -rf /tmp/get-pip.py && \
    rm -r /root/.cache && rm -rf /tmp/*

# ***** 安装golang *****
RUN set -eux && \
    wget --no-check-certificate https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    cd /tmp/ && tar zxvf go${GO_VERSION}.linux-amd64.tar.gz -C /opt && \
    export GOROOT=/opt/go && \
    export GOPATH=/opt/golang && \
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin && \
    mkdir -pv $GOPATH/bin && rm -rf /tmp/* && \
    ln -sfd /opt/go/bin/* /usr/bin/
