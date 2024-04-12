#!/bin/bash

# Function to validate port number
validate_port() {
    if [[ ! $1 =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid port number. Please enter a valid port number."
        exit 1
    fi
}

# Interactive prompt for port numbers
read -p "Enter the port number for the agent (default: 80): " AGENT_PORT_INPUT
validate_port "$AGENT_PORT_INPUT"
AGENT_PORT="${AGENT_PORT_INPUT:-80}"

read -p "Enter the port number for the client (default: 443): " CLIENT_PORT_INPUT
validate_port "$CLIENT_PORT_INPUT"
CLIENT_PORT="${CLIENT_PORT_INPUT:-443}"

# Stop the service
sudo systemctl stop fncloud.service

# Disable the service
sudo systemctl disable fncloud.service

# Remove the service file
sudo rm /etc/systemd/system/fncloud.service

# Reload the systemd daemon
sudo systemctl daemon-reload

# Remove the program file
sudo rm /opt/fncloud/fncloud
sudo rm -r /opt/fncloud

# Remove the log directory
sudo rm -rf /var/log/fncloud

# Remove firewall rules for the selected ports
sudo iptables -D INPUT -m state --state NEW -p tcp --dport "$AGENT_PORT" -j ACCEPT || { echo "Failed to remove firewall rule for port $AGENT_PORT."; }
sudo iptables -D INPUT -m state --state NEW -p tcp --dport "$CLIENT_PORT" -j ACCEPT || { echo "Failed to remove firewall rule for port $CLIENT_PORT."; }

# Save firewall rules persistently
sudo netfilter-persistent save

echo "Service and associated files removed successfully."
