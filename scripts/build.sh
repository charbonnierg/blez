#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/opt/bluez}"


#
# Find host platform
#
function platform {
    case $(arch) in
        x86_64)
            echo "linux-amd64"
            ;;
        aarch64)
            echo "linux-arm64"
            ;;
        armv7l)
            echo "linux-arm-v7"
            ;;
        *)
            >&2 echo "Architecture not supported: $(arch)"
            exit 1
            ;;
    esac
}


# Install system dependencies required to build Bluez project
function installDependencies {
    apt-get update
    apt-get install -y --no-install-recommends \
        automake \
        ca-certificates \
        gcc \
        git \
        libdbus-1-dev \
        libglib2.0-dev \
        libical-dev \
        libreadline-dev \
        libtool \
        libudev-dev \
        make \
        udev
}

# Clone Bluez git repository from github on latest tag
function cloneRepository {
    VERSION="$1"
    git clone https://github.com/bluez/bluez.git \
        --single-branch \
        --branch "$VERSION"
}

# Prepare and run build
function build {
    VERSION="$1"
    ./bootstrap
    ./configure \
        --disable-a2dp \
        --disable-avrcp \
        --disable-bap \
        --disable-cups \
        --disable-hid \
        --disable-hog \
        --disable-manpages \
        --disable-mcp \
        --disable-network \
        --disable-obex \
        --disable-systemd \
        --disable-network \
        --disable-vcp \
        --enable-deprecated \
        --enable-experimental \
        --enable-testing \
        --enable-logger \
        --enable-static \
        --prefix="/opt/bluez-$VERSION"
    # Make sure previous build is deleted
    rm -rf "/opt/bluez-$VERSION"
    # Build
    make -j4
    # Install in prefix
    make install
    mkdir -p "/opt/bluez-$VERSION/etc/dbus-1"
    mkdir -p "/opt/bluez-$VERSION/etc/bluetooth"
    # Copy D-Bus configuration
    cp ./src/bluetooth.conf "/opt/bluez-$VERSION/etc/dbus-1/."
    # Copy bluetooth configuration
    cp ./src/main.conf "/opt/bluez-$VERSION/etc/bluetooth/."
}

# Archive bluez from prefix directory
function archive {
    VERSION="$1"
    mkdir -p $OUTPUT_DIR
    tar -czf "$OUTPUT_DIR/bluez-$VERSION-$(platform).tar.gz" "/opt/bluez-$VERSION"
    echo -e "Created archive in $OUTPUT_DIR/bluez-$VERSION-$(platform).tar.gz"
}

# Build a single version distribution
function build-dist {
    VERSION="$1"
    rm -rf bluez/
    cloneRepository "$VERSION"
    cd bluez/
    build "$VERSION"
    cd -
    archive "$VERSION"
}

# Build all versions
function main {
    installDependencies
    for VERSION in "$@"
    do
        build-dist $VERSION
    done
}

# Run main script
main $@
