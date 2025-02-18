# unifi-rclone

- Custom Install Location: Installs rclone in /data instead of /usr/bin/.

- Ensures /data exists before installing.

- Creates /data Directory If Needed

- Ensures both nano and unzip are installed before proceeding.

- Uses a reusable function (install_package) to keep things clean.

- Maintains --dry-run support to preview actions without making changes.

- Ensures rclone is in the PATH: Adds /data to PATH if it's not there, so you can run rclone from anywhere.

