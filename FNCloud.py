#!/usr/bin/env python3

import socket
import logging
import select
import signal
import os

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Server configuration
SERVER_ADDRESS = '0.0.0.0'  # Listens on all interfaces. You can specify if needed.
CLIENT_PORT = 443  # Port for client connections. You can change.
AGENT_PORT = 80   # Port for agent connections. You can change. If you change this, make sure to update the FNLocal file as well.
BUFFER_SIZE = 256 * 1024  # Reduced buffer size for better performance and security
TIMEOUT = 60  # Timeout in seconds for idle connections (5 minutes)

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
                    logging.info('Connection closed due to inactivity')
                    return

    except Exception as e:
        logging.error(f'Error handling connection: {e}')
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

    # Register signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)

    # Create the server socket for the client
    client_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    client_server_socket.bind((SERVER_ADDRESS, CLIENT_PORT))
    client_server_socket.listen()
    logging.info(f'Server started on port {CLIENT_PORT} for clients')

    # Create the server socket for the agent
    agent_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    agent_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    agent_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)  # Allow multiple sockets to bind to the same port
    agent_server_socket.bind((SERVER_ADDRESS, AGENT_PORT))
    agent_server_socket.listen()
    logging.info(f'Server started on port {AGENT_PORT} for agents')

    try:
        while True:
            # Accept incoming connections from the client and agent
            readable, _, _ = select.select([client_server_socket, agent_server_socket], [], [])

            for sock in readable:
                if sock is client_server_socket:
                    # Accept incoming connection from the client
                    client_socket, _ = client_server_socket.accept()
                    logging.info(f'Connection received from client')

                    # Accept incoming connection from the agent
                    agent_socket, _ = agent_server_socket.accept()
                    logging.info(f'Agent connected')

                    # Handle the connection between client and agent
                    handle_connection(client_socket, agent_socket)

    except Exception as e:
        logging.error(f'Error in main loop: {e}')
    finally:
        # Close the server sockets
        client_server_socket.close()
        agent_server_socket.close()

if __name__ == "__main__":
    main()
