FROM ubuntu:xenial
LABEL maintainer="Jorge Rodriguez <veimox@gmail.org> (@veimox)"

ARG QT_VERSION=5.9.8
ARG IFW_VERSION=3.1.1

# This is required to make the original rpath long so when replaced an error does not occure.
# The replaced rpath can not be longer that the original rpath.
ONBUILD ENV BASE_PATH /tmp/abcdefghijklmn
RUN mkdir -p $BASE_PATH/

ONBUILD ENV DEBIAN_FRONTEND noninteractive
ONBUILD ENV QT_PATH $BASE_PATH/Qt
ONBUILD ENV IFW_PATH $BASE_PATH/QtIFW
ONBUILD ENV QT_DESKTOP $QT_PATH/${QT_VERSION}/gcc_64
ONBUILD ENV PATH $QT_DESKTOP/bin:$IFW_PATH/bin:$PATH

# Install updates & requirements:
#  * git, openssh-client, ca-certificates - clone & build
#  * locales - useful to set utf-8 locale
#  * curl - to download Qt bundle
#  * build-essential, pkg-config, libgl1-mesa-dev - basic Qt build requirements
#  * libsm6, libice6, libxext6, libxrender1, libfontconfig1, libdbus-1-3 - dependencies of the Qt bundle run-file
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
    && apt-get -qq clean

COPY extract-qt-installer.sh /tmp/qt/
COPY extract-ifw.sh /tmp/ifw/

# Download & unpack Qt toolchains & clean
RUN curl -Lo /tmp/qt/installer.run "https://download.qt.io/official_releases/qt/$(echo "${QT_VERSION}" | cut -d. -f 1-2)/${QT_VERSION}/qt-opensource-linux-x64-${QT_VERSION}.run" \
    && QT_CI_PACKAGES=qt.qt5.$(echo "${QT_VERSION}" | tr -d .).gcc_64 /tmp/qt/extract-qt-installer.sh /tmp/qt/installer.run "$QT_PATH" \
    && find "$QT_PATH" -mindepth 1 -maxdepth 1 ! -name "${QT_VERSION}" -exec echo 'Cleaning Qt SDK: {}' \; -exec rm -r '{}' \; \
    && rm -rf /tmp/qt

# Download & unpack Qt Intaller Framework & clean
RUN curl -Lo /tmp/ifw/installer.run "https://download.qt.io/official_releases/qt-installer-framework/${IFW_VERSION}/QtInstallerFramework-linux-x64.run" \
    && /tmp/ifw/extract-ifw.sh /tmp/ifw/installer.run "$IFW_PATH" \
    && rm -rf /tmp/ifw

# Reconfigure locale
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
