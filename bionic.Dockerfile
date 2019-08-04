FROM ubuntu:bionic
LABEL maintainer="Jorge Rodriguez <veimox@gmail.org> (@veimox)"

ARG QT_VERSION=5.12.4
ARG IFW_VERSION=3.1.1

# This is required to make the original rpath long so when replaced an error does not occure.
# The replaced rpath can not be longer that the original rpath.
ENV BASE_PATH /tmp/abcdefghijklmnopqrstuvwxyz
RUN mkdir -p $BASE_PATH/

ENV DEBIAN_FRONTEND noninteractive
ENV QT_PATH $BASE_PATH/Qt
ENV IFW_PATH $BASE_PATH/QtIFW
ENV QT_DESKTOP $QT_PATH/${QT_VERSION}/gcc_64
ENV PATH $QT_DESKTOP/bin:$IFW_PATH/bin:$PATH

# Install updates & requirements:
#  * git, openssh-client, ca-certificates - clone & build
#  * locales - useful to set utf-8 locale
#  * curl, wget - to download Qt bundle and others
#  * build-essential, pkg-config, libgl1-mesa-dev - basic Qt build requirements
#  * p7zip, p7zip-full - extracting 7z files
#  * libsm6, libice6, libxext6, libxrender1, libfontconfig1, libdbus-1-3 - dependencies of the Qt bundle run-file
#  * chrpath - change rpath
RUN apt update && apt full-upgrade -y && apt install -y --no-install-recommends \
    git \
    openssh-client \
    ca-certificates \
    locales \
    curl \
    build-essential \
    pkg-config \
    libgl1-mesa-dev \
    libsm6 \
    libice6 \
    libxext6 \
    libxrender1 \
    libfontconfig1 \
    libdbus-1-3 \
    wget \
    p7zip \
    p7zip-full \
    python \
    chrpath \
    libxml2-dev \
    zlib1g-dev \
    libboost-dev \
    libyaml-cpp-dev \
    autoconf \
    software-properties-common \
    cmake \
    gettext-base \
    && apt-get -qq clean

COPY extract-qt-installer.sh /tmp/qt/
COPY extract-ifw.sh /tmp/ifw/

# Download & unpack Qt toolchains & clean
RUN curl -Lo /tmp/qt/installer.run "https://download.qt.io/official_releases/qt/$(echo "${QT_VERSION}" | cut -d. -f 1-2)/${QT_VERSION}/qt-opensource-linux-x64-${QT_VERSION}.run" \
    && QT_CI_PACKAGES="qt.qt5.$(echo "${QT_VERSION}" | tr -d .).gcc_64,qt.qt5.$(echo "${QT_VERSION}" | tr -d .).qtscript" /tmp/qt/extract-qt-installer.sh /tmp/qt/installer.run "$QT_PATH" \
    && find "$QT_PATH" -mindepth 1 -maxdepth 1 ! -name "${QT_VERSION}" -exec echo 'Cleaning Qt SDK: {}' \; -exec rm -r '{}' \; \
    && rm -rf /tmp/qt

# Download & unpack Qt Intaller Framework & clean
RUN curl -Lo /tmp/ifw/installer.run "https://download.qt.io/official_releases/qt-installer-framework/${IFW_VERSION}/QtInstallerFramework-linux-x64.run" \
    && /tmp/ifw/extract-ifw.sh /tmp/ifw/installer.run "$IFW_PATH" \
    && rm -rf /tmp/ifw

# Reconfigure locale
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
