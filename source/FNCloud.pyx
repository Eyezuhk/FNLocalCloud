#!/usr/bin/env python3

import socket
import logging
import select
import signal
import os
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Server configuration
SERVER_ADDRESS = '0.0.0.0'  # Listens on all interfaces
BUFFER_SIZE = 4 * 1024  # Reduced buffer size for better performance and security
TIMEOUT = 2  # Timeout in seconds for idle connections (2 seconds)

def handle_connection(client_socket, agent_socket):
    """
    Forwards data between a client and an agent until the connection is closed or idle.

    Args:
        client_socket (socket.socket): The socket for the client connection.
        agent_socket (socket.socket): The socket for the agent connection.
    """
    try:
        client_socket.settimeout(TIMEOUT)
        agent_socket.settimeout(TIMEOUT)

        client_buffer = bytearray(BUFFER_SIZE)
        agent_buffer = bytearray(BUFFER_SIZE)

        # Get the client's and agent's address
        client_address = client_socket.getpeername()
        agent_address = agent_socket.getpeername()
        
        while True:
            # Check for incoming data from either the client or agent
            readable, _, _ = select.select([client_socket, agent_socket], [], [])

            for sock in readable:
                try:
                    if sock is client_socket:
                        # Receive data from the client into the client buffer
                        bytes_received = client_socket.recv_into(client_buffer)
                        if bytes_received == 0:
                            # If no data, close the connection
                            client_socket.close()
                            agent_socket.close()
                            return

                        # Forward data from client to agent
                        agent_socket.sendall(client_buffer[:bytes_received])

                    else:
                        # Receive data from the agent into the agent buffer
                        bytes_received = agent_socket.recv_into(agent_buffer)
                        if bytes_received == 0:
                            # If no data, close the connection
                            client_socket.close()
                            agent_socket.close()
                            return

                        # Forward data from agent to client
                        client_socket.sendall(agent_buffer[:bytes_received])

                except socket.timeout:
                    # Close idle connections after the timeout
                    client_socket.close()
                    agent_socket.close()
                    logging.info(f'Connection from {client_address} closed due to inactivity')
                    return

    except Exception as e:
        logging.error(f'Error handling connection from {client_address}: {e}')
    finally:
        # Close the client and agent sockets
        client_socket.close()
        agent_socket.close()

def signal_handler(signal, frame):
    """
    Signal handler to gracefully exit the program.

    Args:
        signal (int): The signal number.
        frame (frame): The current stack frame.
    """
    logging.info('Server shutting down.')
    os._exit(0)

def main():
    """
    Sets up server sockets for clients and agents, listens for connections,
    and establishes communication between them using handle_connection().
    """

    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Server to forward data between client and agent.")
    parser.add_argument("-cp","--client-port", type=int, default=443, help="Port for client connections (default: 443)")      
    parser.add_argument("-ap","--agent-port", type=int, default=80, help="Port for agent connections (default: 80)")  
    args = parser.parse_args()

    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)

    # Create the server socket for the agent
    agent_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    agent_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    agent_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)  # Allow multiple sockets to bind to the same port
    agent_server_socket.bind((SERVER_ADDRESS, args.agent_port))
    agent_server_socket.listen()
    logging.info(f'Server started on port {args.agent_port} for agents')

    # Create the server socket for the client
    client_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    client_server_socket.bind((SERVER_ADDRESS, args.client_port))
    client_server_socket.listen()
    logging.info(f'Server started on port {args.client_port} for clients')


    try:
        while True:
            # Accept incoming connections from the client and agent
            readable, _, _ = select.select([client_server_socket, agent_server_socket], [], [])

            for sock in readable:
                if sock is client_server_socket:
                    # Accept incoming connection from the client
                    client_socket, client_address = client_server_socket.accept()
                    logging.info(f'Connection received from client {client_address}')

                    # Accept incoming connection from the agent
                    agent_socket, agent_address = agent_server_socket.accept()
                    logging.info(f'Agent connected from {agent_address}')

                    # Handle the connection between client and agent
                    handle_connection(client_socket, agent_socket)

    except Exception as e:
        logging.error(f'Error in main loop: {e}')
    finally:
        # Close the server sockets
        client_server_socket.close()
        agent_server_socket.close()

main()
