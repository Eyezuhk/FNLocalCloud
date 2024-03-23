import socket
import logging
import select

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Server configuration
SERVER_ADDRESS = '0.0.0.0'  # Listens on all interfaces. You can specify if needed.
CLIENT_PORT = 443  # Port for client connections. You can change.
AGENT_PORT = 80   # Port for agent connections. You can change. If you change this, make sure to update the FNLocal file as well.
BUFFER_SIZE = 256 * 1024  

# BUFFER_SIZE: Maximum amount of data to receive at once (256 KB)
# This value can be adjusted to optimize performance.
# For slower connections, it may be necessary to reduce the value to avoid network congestion.
# For faster connections, the value can be increased to improve data throughput.

def handle_connection(client_socket, agent_socket):
    """
    Forwards data between a client and an agent until the connection is closed.

    Args:
        client_socket (socket.socket): The socket for the client connection.
        agent_socket (socket.socket): The socket for the agent connection.
    """

    try:
        while True:
            # Check for incoming data from either the client or agent
            readable, _, _ = select.select([client_socket, agent_socket], [], [])

            for sock in readable:
                data = sock.recv(BUFFER_SIZE)
                if not data:
                    # If no data, close the connection
                    client_socket.close()
                    agent_socket.close()
                    return

                if sock is client_socket:
                    # Forward data from client to agent
                    agent_socket.sendall(data)
                else:
                    # Forward data from agent to client
                    client_socket.sendall(data)

    except Exception as e:
        logging.error(f'Error handling connection: {e}')
    finally:
        # Close the client and agent sockets
        client_socket.close()
        agent_socket.close()

def main():
    """
    Sets up server sockets for clients and agents, listens for connections,
    and establishes communication between them using handle_connection().

    Raises:
        KeyboardInterrupt: If the program is interrupted by the user (Ctrl+C).
    """

    # Create the server socket for the client
    client_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    client_server_socket.bind((SERVER_ADDRESS, CLIENT_PORT))
    client_server_socket.listen()
    logging.info(f'Server started on port {CLIENT_PORT} for clients')

    # Create the server socket for the agent
    agent_server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    agent_server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
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

    except KeyboardInterrupt:
        logging.info('Server shutting down.')
    finally:
        # Close the server sockets
        client_server_socket.close()
        agent_server_socket.close()

if __name__ == "__main__":
    main()
