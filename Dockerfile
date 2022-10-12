###############################################################################
# Copyright (C) 2022, Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
###############################################################################
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive 

# install dependences:

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y -q \
    bc \
    cpio \
    curl \
    gawk \
    sed \
    build-essential \
    gcc \
    gcc-multilib \
    git \
    make \
    iproute2 \
    net-tools \
    tftpd-hpa \
    bison \
    flex bison \
    gnupg \
    gnupg wget \
    diffstat \
    chrpath \
    socat \
    autoconf \
    tar \
    xterm \
    unzip \
    gzip \
    texinfo \
    zlib1g-dev \
    automake \
    pax \
    xz-utils \
    debianutils \
    rsync \
    xxd \
    expect \
    kmod \
    libtool \
    libssl-dev \
    libselinux1 \
    libegl1-mesa \
    libsdl1.2-dev \
    libncurses5-dev \
    lib32z1-dev \
    libglib2.0-dev \
    libgtk2.0-0 \
    libidn11 \
    libtinfo5 \
    libtool-bin \
    lsb-release \
    tofrodos \
    u-boot-tools \
    xvfb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update &&  \
    apt-get install -y -q \
    zlib1g:i386 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y \
    locales && \
    locale-gen en_US.UTF-8 && \
    update-locale

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


## user
ENV BUILD_USER build

RUN apt-get update && \
    apt-get install -y sudo && \
    echo "${BUILD_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ARG BUILD_UID
ARG BUILD_GID

# create a non-root user that will perform the actual build
RUN groupadd ${BUILD_GID:+-g ${BUILD_GID}} ${BUILD_USER} && \
    useradd  ${BUILD_UID:+-u ${BUILD_UID}} -g ${BUILD_USER} \
        -m   ${BUILD_USER}

USER ${BUILD_USER}


