#!/bin/bash

# Define script and service file paths
SCRIPT_PATH="/data/setup_gdrive_backup.sh"
SERVICE_PATH="/etc/systemd/system/gdrive_backup.service"
CRON_ENTRY="0 8 * * * /bin/bash /data/Google_Drive_Backups.sh"

# Create the setup script
cat <<EOL > "$SCRIPT_PATH"
#!/bin/bash

# Define the desired crontab entry
CRON_ENTRY="$CRON_ENTRY"

# Check if the crontab entry already exists
(crontab -l 2>/dev/null | grep -F "$CRON_ENTRY") || {
    # Add the crontab entry if it doesn't exist
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
}
EOL

# Make the script executable
chmod +x "$SCRIPT_PATH"

# Ensure the cron job exists
(crontab -l 2>/dev/null | grep -F "$CRON_ENTRY") || {
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
}

# Create the systemd service file
cat <<EOL > "$SERVICE_PATH"
[Unit]
Description=Setup crontab for Google Drive Backups
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable, and start the service
systemctl daemon-reload
systemctl enable gdrive_backup
systemctl start gdrive_backup

