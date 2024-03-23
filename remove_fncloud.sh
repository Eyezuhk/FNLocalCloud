#!/bin/bash

# Stop the service
sudo systemctl stop fncloud.service

# Disable the service
sudo systemctl disable fncloud.service

# Remove the service file
sudo rm /etc/systemd/system/fncloud.service

# Reload the systemd daemon
sudo systemctl daemon-reload

# Remove the program file
sudo rm /usr/local/bin/FNCloud.py

# Remove the log directory
sudo rm -rf /var/log/fncloud

echo "Service and associated files removed successfully."
