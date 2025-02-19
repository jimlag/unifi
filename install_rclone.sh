#!/bin/bash

INSTALL_DIR="/data"  # Custom installation directory
RCLONE_DIR="$INSTALL_DIR/rclone"
RCLONE_PATH="$RCLONE_DIR/rclone"
BACKUP_SCRIPT="$INSTALL_DIR/Google_Drive_Backups.sh"

# Ask user for the location name
read -rp "Enter the location name of this device: " LOCATION

# Ensure the installation directories exist
if [[ ! -d "$RCLONE_DIR" ]]; then
    echo "Creating installation directory at $RCLONE_DIR..."
    sudo mkdir -p "$RCLONE_DIR"
    sudo chown "$(whoami)" "$RCLONE_DIR"
fi

# Function to install required packages
install_package() {
    PACKAGE_NAME=$1
    if ! command -v "$PACKAGE_NAME" &> /dev/null; then
        echo "$PACKAGE_NAME is not installed. Installing..."
        sudo apt update && sudo apt install -y "$PACKAGE_NAME"
    else
        echo "$PACKAGE_NAME is already installed."
    fi
}

# Install required packages
install_package nano
install_package unzip
install_package cron

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

# Function to update/install rclone in /data/rclone
update_rclone() {
    ARCH=$(get_architecture)
    LATEST_VERSION=$(get_latest_version)

    echo "Detected system architecture: $ARCH"
    echo "Downloading rclone v$LATEST_VERSION for $ARCH into $RCLONE_DIR..."

    URL="https://downloads.rclone.org/v$LATEST_VERSION/rclone-v$LATEST_VERSION-linux-$ARCH.zip"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit

    curl -O "$URL"
    unzip "rclone-v$LATEST_VERSION-linux-$ARCH.zip"
    cd "rclone-v$LATEST_VERSION-linux-$ARCH" || exit

    mv rclone "$RCLONE_DIR/"
    chmod +x "$RCLONE_PATH"

    cd ~
    rm -rf "$TEMP_DIR"

    echo "rclone installed in $RCLONE_DIR successfully!"
}
# Function to create the Google Drive backup script
create_backup_script() {
    echo "Creating backup script at $BACKUP_SCRIPT..."

    BACKUP_CONTENT="#!/bin/bash
$data/rclone copy --update --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 \"/etc/unifi-protect/backups/\" \"Google Drive Backup:Backu>

    echo "$BACKUP_CONTENT" > "$BACKUP_SCRIPT"
    chmod +x "$BACKUP_SCRIPT"
    echo "Backup script created successfully!"
}

# Function to set up the cron job for automatic backups at 8 AM
setup_cron_job() {
    CRON_JOB="0 8 * * * /bin/bash /data/Google_Drive_Backups.sh"
    
    # Check if the cron job already exists
    if crontab -l | grep -q "$BACKUP_SCRIPT"; then
        echo "Cron job already exists. Skipping..."
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "Cron job added: Runs daily at 8 AM."
    fi
}

# Get versions
INSTALLED_VERSION=$(get_installed_version)
LATEST_VERSION=$(get_latest_version)

echo "Installed version: $INSTALLED_VERSION"
echo "Latest version: v$LATEST_VERSION"

# Compare versions
if [[ "$INSTALLED_VERSION" == "none" ]]; then
    echo "rclone is not installed. Installing now..."
    update_rclone
elif [[ "$INSTALLED_VERSION" != "v$LATEST_VERSION" ]]; then
    echo "Newer version available (v$LATEST_VERSION). Updating..."
    update_rclone
else
    echo "rclone is already up to date."
fi

# Ensure rclone is in PATH
if ! echo "$PATH" | grep -q "$RCLONE_DIR"; then
    echo "Adding $RCLONE_DIR to PATH..."
    echo "export PATH=\$PATH:$RCLONE_DIR" >> ~/.bashrc
    source ~/.bashrc
fi

# Create the backup script
create_backup_script

# Set up the cron job
setup_cron_job

