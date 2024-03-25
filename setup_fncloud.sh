#!/bin/bash

echo "..................::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::......................
...................:::::::::::::::::::::::::::~!7???7!^::::::::::::::::::::::.......................
......................::::::::::::::::::::~YB&@@@@@@@@@&BJ~:::::::::::::::::........................
.......................:::::::::::::::::7B@@@@@@@@@@@@@@@@@B!::::::::::::...........................
..........................::::::::::::^G@@@@@@@@@@@@@@@@@@@@@P:.:::..::.............................
..............................::......5#&&&&&&#BPYYYYPB#&&&&&@B:....................................
.................................:~7?J?7!!YB5!!?YPPP5Y7!!5#&&&&Y....................................
...............................!G&&&&&&&&G7::P#&&&&&&&&#P~^JP#&G:...................................
..............................?####&&&&##&&P:JBY?7777?YG#B57^^5P....................................
.............................^7777!!75####B#7.^7YPPPPY7^~5BGP!.^^7J555J7~:..........................
..........................~5B######GY~^YBBBY.7GBGYJJJYY?:.7JJ7:~Y5PPPPPP5J^.........................
........................:5######BBBBBBY.!5?..77?:~?????????????JJJJJJJYYYY5Y^.......................
........................P##BBBBBBBGGGGY::~7JJJ?7~^:^!!!!!77777777777777?????!.......................
.......................!#BBBGGGGGGGG5^:75555J????7:.~???????????????JJJJJJJJJ^......................
.......................!BGGGGGPPPPPJ.:Y5YYJ:^7777!!~^..~!77!!7777777777777777:......................
.......................:PGPPPPP555Y~ 7YYJJ?~^~^^^~~~^::^~~~~~~~~~~~~~~~~!!!!~.......................
........................^PPP5555YYJ~ ~YJJ!!!!^:.:!!!!!!!!!!!!!!!!!!!!777!777:.......................
........................ .7555YYYJJ7:.~?J?~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^..........................
.......................... .~7JJJJJ?7~:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::...........................
............................  ..:::::::....                             ............................
.................................    ...............................................................
............................... ................. .... .............................................
.....................5BGGGG: ~#Y. .YB...:#?......?GBBGJ....7GBBG!...:BB....~#~......................
.....................&@!!!:. !@@&?.B@:..^@P ....&&!::!&&..#@7::!^...&@@#.. ?@7 .....................
.....................#@PP5.. !@J!&&&@:..:@5 ...:@#.  .B@:.@&.  ....#@PG@B. ?@7 .....................
.....................#&.  .. !@7 .J@@:..:@&GGB! ~B#GG#B~..^B&BB#J 5@J77J@Y 7@#GBY...................
......................:.......:... .:. ..:::::..  .:^:  ... .::...:.    ::..:::::...................
.....................................^^....:.....^^...^.:....^^:....................................
................................... 75!:...G^...5??J .P^5^...G7P:...................................
.....................................^^....^~:...^^...:~^....^^:....................................
.....................................  ..........  .... .....  ....................................."

# Function to check if the user is root
is_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root."
        exit 1
    fi
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    iptables -D INPUT -m state --state NEW -p tcp --dport "$AGENT_PORT" -j ACCEPT 2>/dev/null
    iptables -D INPUT -m state --state NEW -p tcp --dport "$CLIENT_PORT" -j ACCEPT 2>/dev/null
    netfilter-persistent save >/dev/null 2>&1
    systemctl stop fncloud.service >/dev/null 2>&1
    systemctl disable fncloud.service >/dev/null 2>&1
    rm -rf /usr/local/bin/FNCloud.py /var/log/fncloud /etc/systemd/system/fncloud.service >/dev/null 2>&1
    echo "Cleanup complete."
}

# Trap the exit signal and call the cleanup function
trap cleanup EXIT

# Check if the user is root
is_root

# Function to install Python if not already installed
install_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 is not installed. Installing Python3..."
        if [ -x "$(command -v apt-get)" ]; then
            apt-get update
            apt-get install -y python3
        elif [ -x "$(command -v yum)" ]; then
            yum install -y python3
        elif [ -x "$(command -v zypper)" ]; then
            zypper install -y python3
        else
            echo "Could not find an appropriate package manager to install Python3."
            echo "Please install Python3 manually and rerun the script."
            exit 1
        fi
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
        echo "Installing missing dependencies..."
        if [ -x "$(command -v apt-get)" ]; then
            apt-get update
            apt-get install -y "${missing_deps[@]}"
        elif [ -x "$(command -v yum)" ]; then
            yum install -y "${missing_deps[@]}"
        elif [ -x "$(command -v zypper)" ]; then
            zypper install -y "${missing_deps[@]}"
        else
            echo "Could not find an appropriate package manager to install dependencies."
            echo "Please install the missing dependencies manually before continuing."
            exit 1
        fi
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
chmod 640 /usr/local/bin/FNCloud.py || { echo "Failed to set permissions for the FNCloud.py file."; exit 1; }

# Get the current user
current_user=$(whoami)

# Set the correct permissions for the log directory
chown -R "$current_user:$current_user" /var/log/fncloud || { echo "Failed to set permissions for the /var/log/fncloud directory."; exit 1; }

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
User=$current_user
Environment=HOME=/home/$current_user
#ExecStart=/usr/bin/sudo /usr/bin/python3 /usr/local/bin/FNCloud.py > /var/log/fncloud/output_server.log 2>&1
ExecStart=/usr/bin/python3 /usr/local/bin/FNCloud.py > /var/log/fncloud/output_server.log 2>&1
Restart=always
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

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
