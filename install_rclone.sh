#!/bin/bash

INSTALL_DIR="/data"  # Custom installation directory
RCLONE_PATH="$INSTALL_DIR/rclone"

# Enable dry-run mode if the flag is provided
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[DRY-RUN MODE ENABLED] No changes will be made."
fi

# Ensure the installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "Creating installation directory at $INSTALL_DIR..."
    if [[ "$DRY_RUN" == false ]]; then
        sudo mkdir -p "$INSTALL_DIR"
        sudo chown "$(whoami)" "$INSTALL_DIR"
    fi
fi

# Function to install required packages
install_package() {
    PACKAGE_NAME=$1
    if ! command -v "$PACKAGE_NAME" &> /dev/null; then
        echo "$PACKAGE_NAME is not installed. Installing..."
        if [[ "$DRY_RUN" == false ]]; then
            sudo apt update && sudo apt install -y "$PACKAGE_NAME"
        else
            echo "[DRY-RUN] Skipping installation of $PACKAGE_NAME."
        fi
    else
        echo "$PACKAGE_NAME is already installed."
    fi
}

# Install nano and unzip before proceeding
install_package nano
install_package unzip

# Function to get the installed version of rclone
get_installed_version() {
    if [[ -x "$RCLONE_PATH" ]]; then
        "$RCLONE_PATH" --version | head -n 1 | awk '{print $2}'
    else
        echo "none"
    fi
}

# Function to get the latest available version of rclone
get_latest_version() {
    curl -s https://api.github.com/repos/rclone/rclone/releases/latest | grep '"tag_name":' | awk -F '"' '{print $4}' | sed 's/v//'
}

# Function to detect system architecture
get_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) echo "amd64" ;;
        i386|i686) echo "386" ;;
        armv7l) echo "arm" ;;
        aarch64) echo "arm64" ;;
        *) echo "unsupported"; exit 1 ;;
    esac
}

# Function to update/install rclone in /data
update_rclone() {
    ARCH=$(get_architecture)
    LATEST_VERSION=$(get_latest_version)

    echo "Detected system architecture: $ARCH"
    echo "Would download rclone $LATEST_VERSION for $ARCH into $INSTALL_DIR..."

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Skipping download and installation."
        return
    fi

    URL="https://downloads.rclone.org/v$LATEST_VERSION/rclone-v$LATEST_VERSION-linux-$ARCH.zip"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit

    curl -O "$URL"
    unzip "rclone-v$LATEST_VERSION-linux-$ARCH.zip"
    cd "rclone-v$LATEST_VERSION-linux-$ARCH" || exit

    mv rclone "$INSTALL_DIR/"
    chmod +x "$RCLONE_PATH"

    cd ~
    rm -rf "$TEMP_DIR"

    echo "rclone installed in $INSTALL_DIR successfully!"
}

# Get versions
INSTALLED_VERSION=$(get_installed_version)
LATEST_VERSION=$(get_latest_version)

echo "Installed version: $INSTALLED_VERSION"
echo "Latest version: $LATEST_VERSION"

# Compare versions
if [[ "$INSTALLED_VERSION" == "none" ]]; then
    echo "rclone is not installed. Would install now..."
    if [[ "$DRY_RUN" == false ]]; then
        update_rclone
    fi
elif [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
    echo "Newer version available. Would update..."
    if [[ "$DRY_RUN" == false ]]; then
        update_rclone
    fi
else
    echo "rclone is already up to date."
fi

# Ensure rclone is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "Adding $INSTALL_DIR to PATH..."
    echo "export PATH=\$PATH:$INSTALL_DIR" >> ~/.bashrc
    source ~/.bashrc
fi
