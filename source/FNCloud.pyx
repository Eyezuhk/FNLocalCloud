#!/usr/bin/env python3

import socket
import logging
import select
import signal
import os
import argparse
from typing import Tuple

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Server configuration
SERVER_ADDRESS = '0.0.0.0'
DEFAULT_BUFFER_SIZE = 32 * 1024  # 32KB default buffer
TIMEOUT = 2.0

def handle_connection(client_socket: socket.socket, 
                     agent_socket: socket.socket, 
                     buffer_size: int) -> None:
    """
    Handles the bidirectional data transfer between client and agent.
    
    Args:
        client_socket: Socket connected to the client
        agent_socket: Socket connected to the agent
        buffer_size: Size of the transfer buffer in bytes
    """
    try:
        # Set socket timeouts
        client_socket.settimeout(TIMEOUT)
        agent_socket.settimeout(TIMEOUT)

        # Pre-allocate buffers
        client_buffer = memoryview(bytearray(buffer_size))
        agent_buffer = memoryview(bytearray(buffer_size))

        client_address = client_socket.getpeername()
        agent_address = agent_socket.getpeername()
        
        logging.info(f'Starting forwarding between client {client_address} and agent {agent_address}')
        
        while True:
            try:
                # Use select to monitor both sockets
                readable, _, exceptional = select.select(
                    [client_socket, agent_socket],
                    [],
                    [client_socket, agent_socket],
                    TIMEOUT
                )

                if exceptional:
                    logging.warning('Exceptional condition detected')
                    break

                # Handle readable sockets
                for sock in readable:
                    try:
                        # Determine source and destination sockets
                        src_socket = sock
                        dst_socket = agent_socket if sock is client_socket else client_socket
                        buffer = client_buffer if sock is client_socket else agent_buffer
                        
                        # Receive data
                        bytes_received = src_socket.recv_into(buffer)
                        if bytes_received == 0:
                            return  # Connection closed by peer
                            
                        # Send data
                        dst_socket.sendall(buffer[:bytes_received])

                    except socket.timeout:
                        continue
                    except (ConnectionResetError, BrokenPipeError) as e:
                        logging.error(f'Connection error: {e}')
                        return

            except select.error as e:
                logging.error(f'Select error: {e}')
                break

    except Exception as e:
        logging.error(f'Error in connection handler: {e}')
    finally:
        # Clean up sockets
        for sock in [client_socket, agent_socket]:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except:
                pass
            try:
                sock.close()
            except:
                pass

def create_server_socket(port: int) -> socket.socket:
    """
    Creates and configures a server socket.
    
    Args:
        port: Port number to bind to
        
    Returns:
        Configured server socket
    """
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    # Set TCP keepalive
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
    
    # Disable Nagle's algorithm for better performance
    server_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    
    # Set socket buffer sizes
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, DEFAULT_BUFFER_SIZE)
    server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, DEFAULT_BUFFER_SIZE)
    
    server_socket.bind((SERVER_ADDRESS, port))
    server_socket.listen(5)
    return server_socket

def main():
    """Main server function that handles command line arguments and runs the server."""
    parser = argparse.ArgumentParser(description="Optimized data forwarding server")
    parser.add_argument("-cp", "--client-port", type=int, required=True,
                      help="Port for client connections")
    parser.add_argument("-ap", "--agent-port", type=int, required=True,
                      help="Port for agent connections")
    parser.add_argument("-b", "--buffer-size", type=int, default=DEFAULT_BUFFER_SIZE,
                      help=f"Buffer size in bytes (default: {DEFAULT_BUFFER_SIZE})")
    args = parser.parse_args()

    # Create server sockets
    client_server_socket = create_server_socket(args.client_port)
    agent_server_socket = create_server_socket(args.agent_port)

    logging.info(f'Server started - Client port: {args.client_port}, Agent port: {args.agent_port}')
    logging.info(f'Buffer size: {args.buffer_size} bytes')

    def cleanup(signum, frame):
        """Signal handler for graceful shutdown"""
        logging.info('Server shutting down...')
        client_server_socket.close()
        agent_server_socket.close()
        os._exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    try:
        while True:
            try:
                # Wait for client connection
                client_socket, client_address = client_server_socket.accept()
                logging.info(f'Client connected from {client_address}')

                # Wait for agent connection
                agent_socket, agent_address = agent_server_socket.accept()
                logging.info(f'Agent connected from {agent_address}')

                # Handle the connection
                handle_connection(client_socket, agent_socket, args.buffer_size)
                
            except socket.error as e:
                logging.error(f'Socket error: {e}')
                if 'client_socket' in locals():
                    client_socket.close()
            except Exception as e:
                logging.error(f'Error processing connections: {e}')
                if 'client_socket' in locals():
                    client_socket.close()

    except Exception as e:
        logging.error(f'Fatal error in main loop: {e}')
    finally:
        client_server_socket.close()
        agent_server_socket.close()

if __name__ == "__main__":
    main()
