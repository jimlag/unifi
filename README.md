# unifi-rclone

Compatible devices:

UNVR

UNVR-PRO

----

✅ Custom Install Location: Installs rclone in **/data** instead of **/usr/bin/**.

✅ Ensures /data exists before installing.

✅ Creates /data Directory If Needed

✅ Ensures both **nano** and **unzip** are installed before proceeding.

✅ Maintains **--dry-run** support to preview actions without making changes.

✅ Ensures rclone is in the **PATH**: Adds /data to PATH if it's not there, so you can run rclone from anywhere.

✅ Prompts the user for a location name and uses it dynamically in the backup script.

✅ Creates the Google_Drive_Backups.sh script in /data/rclone.

✅ Keeps the script executable by setting the right permissions.

-----------------------------------------------------
If **--dry-run** is used:

- Shows what would happen without downloading or installing anything.
- No files are modified.

Without **--dry-run**, it updates as normal.

-----------------------------------------------------

# How to Use the Script:

To install/update rclone in /data:
----
./update_rclone.sh

 To check what will happen (dry-run mode):
 ----

./update_rclone.sh --dry-run

To verify the installation:
----

/data/rclone --version
