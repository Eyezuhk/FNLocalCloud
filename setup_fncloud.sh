#!/bin/bash

# Function to check if the user is root
is_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

# Function to install Python if not already installed
install_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 is not installed. Installing Python3..."
        apt-get update
        apt-get install -y python3
        if ! command -v python3 >/dev/null 2>&1; then
            echo "Failed to install Python3. Please install it manually and rerun the script."
            exit 1
        fi
    fi
}

# Check if Python is installed and install if necessary
install_python

# Print Python version information
python_version=$(python3 --version 2>&1)
echo "Python version: $python_version"

# Check dependencies
check_dependencies() {
    dependencies=("wget" "sed" "iptables" "netfilter-persistent")
    missing_deps=()

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    if [ "${#missing_deps[@]}" -gt 0 ]; then
        echo "The following dependencies are missing:"
        for dep in "${missing_deps[@]}"; do
            echo "- $dep"
        done
        echo "Please install the missing dependencies before continuing."
        exit 1
    fi
}

# Validate port input
validate_port() {
    local port="$1"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Invalid input. The port must be a number between 1 and 65535."
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

# Check if the user is root
is_root

# Check dependencies
check_dependencies

# Download the program from GitHub
if ! wget -O FNCloud.py https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/FNCloud.py; then
    echo "Failed to download the FNCloud.py file from GitHub."
    exit 1
fi

# Modify the downloaded file to update port configurations
sed -i "s/CLIENT_PORT = \([0-9]*\)/CLIENT_PORT = $CLIENT_PORT/" FNCloud.py || { echo "Failed to modify the FNCloud.py file."; exit 1; }
sed -i "s/AGENT_PORT = \([0-9]*\)/AGENT_PORT = $AGENT_PORT/" FNCloud.py || { echo "Failed to modify the FNCloud.py file."; exit 1; }

# Move the program to the appropriate location
mv FNCloud.py /usr/local/bin/ || { echo "Failed to move the FNCloud.py file to /usr/local/bin/."; exit 1; }

# Create a directory for logs
mkdir -p /var/log/fncloud || { echo "Failed to create the /var/log/fncloud directory."; exit 1; }

# Set the correct permissions for the program
chmod 755 /usr/local/bin/FNCloud.py || { echo "Failed to set permissions for the FNCloud.py file."; exit 1; }

# Set the correct permissions for the log directory
chown -R ubuntu:ubuntu /var/log/fncloud || { echo "Failed to set permissions for the /var/log/fncloud directory."; exit 1; }

# Configure firewall rules
echo "Configuring firewall rules..."

# Check if ports are already in use
if ss -ntl | awk '{print $4}' | grep -q ":$AGENT_PORT\$"; then
    echo "Port $AGENT_PORT is already in use. Choose a different port."
    exit 1
fi

if ss -ntl | awk '{print $4}' | grep -q ":$CLIENT_PORT\$"; then
    echo "Port $CLIENT_PORT is already in use. Choose a different port."
    exit 1
fi

# Add firewall rules for the selected ports
iptables -I INPUT -m state --state NEW -p tcp --dport "$AGENT_PORT" -j ACCEPT || { echo "Failed to add firewall rule for port $AGENT_PORT."; exit 1; }
iptables -I INPUT -m state --state NEW -p tcp --dport "$CLIENT_PORT" -j ACCEPT || { echo "Failed to add firewall rule for port $CLIENT_PORT."; exit 1; }

# Save firewall rules persistently
if ! netfilter-persistent save; then
    echo "Failed to save persistent firewall rules."
    exit 1
fi

# Create the systemd service file with the specified port numbers
cat > /etc/systemd/system/fncloud.service << EOT
[Unit]
Description=FNCloud
After=network.target

[Service]
User=ubuntu
Environment=HOME=/home/ubuntu
ExecStart=/usr/bin/sudo /usr/bin/python3 /usr/local/bin/FNCloud.py > /var/log/fncloud/output_server.log 2>&1
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Reload the systemd daemon
systemctl daemon-reload || { echo "Failed to reload the systemd daemon."; exit 1; }

# Enable and start the service
systemctl enable fncloud.service || { echo "Failed to enable the fncloud.service."; exit 1; }
systemctl start fncloud.service || { echo "Failed to start the fncloud.service."; exit 1; }

# Sleep for 1 second
sleep 1

# Check the status of the service
systemctl status fncloud.service

echo "Setup complete."
