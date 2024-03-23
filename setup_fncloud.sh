#!/bin/bash

# Interactive prompt for port numbers
read -p "Enter the port number for the agent (default: 80): " AGENT_PORT_INPUT
read -p "Enter the port number for the client (default: 443): " CLIENT_PORT_INPUT

# Use default ports if no input provided
AGENT_PORT=${AGENT_PORT_INPUT:-80}
CLIENT_PORT=${CLIENT_PORT_INPUT:-443}

# Download the program from GitHub
wget -O FNCloud.py https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/FNCloud.py

# Modify the downloaded file to update port configurations
sed -i "s/CLIENT_PORT = [0-9]*/CLIENT_PORT = $CLIENT_PORT/" FNCloud.py
sed -i "s/AGENT_PORT = [0-9]*/AGENT_PORT = $AGENT_PORT/" FNCloud.py

# Move the program to the appropriate location
sudo mv FNCloud.py /usr/local/bin/

# Create a directory for logs
sudo mkdir -p /var/log/fncloud

# Set the correct permissions for the program
sudo chmod 755 /usr/local/bin/FNCloud.py

# Set the correct permissions for the log directory
sudo chown -R ubuntu:ubuntu /var/log/fncloud

# Configure firewall rules
echo "Configuring firewall rules..."

# Define the default ports if not provided by the user
DEFAULT_AGENT_PORT=80
DEFAULT_CLIENT_PORT=443

# Define the final port numbers
FINAL_AGENT_PORT=${AGENT_PORT:-$DEFAULT_AGENT_PORT}
FINAL_CLIENT_PORT=${CLIENT_PORT:-$DEFAULT_CLIENT_PORT}

# Add firewall rules for the selected ports
sudo iptables -I INPUT -m state --state NEW -p tcp --dport $FINAL_AGENT_PORT -j ACCEPT
sudo iptables -I INPUT -m state --state NEW -p tcp --dport $FINAL_CLIENT_PORT -j ACCEPT

# Save firewall rules persistently
sudo netfilter-persistent save

# Create the systemd service file with the specified port numbers
sudo tee /etc/systemd/system/fncloud.service > /dev/null <<EOT
[Unit]
Description=FNCloud
After=network.target

[Service]
User=ubuntu
Environment=HOME=/home/ubuntu
ExecStart=/usr/bin/python3 /usr/local/bin/FNCloud.py > /var/log/fncloud/output_server.log 2>&1
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Reload the systemd daemon
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable fncloud.service
sudo systemctl start fncloud.service

# Check the status of the service
sudo systemctl status fncloud.service

echo "Setup complete."
