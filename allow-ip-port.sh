#!/bin/bash

# Prompt the user to enter the IP address and port number
read -p "Enter the IP address: " ip_address
read -p "Enter the port number: " port_number

# Add a rule to allow access to the specified port only for the specified IP address
iptables -A INPUT -p tcp --dport $port_number -s $ip_address -j ACCEPT

# Add an explanatory comment
iptables -A INPUT -m comment --comment "Allows access to port $port_number only for IP $ip_address" -j ACCEPT
