import socket
import logging
import threading
import time

# Configure logging
# Set up logging to display log messages with a specific format
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Server configuration
SERVER_ADDRESS = 'YOUR_SERVER_IP' 
SERVER_PORT = 80 # You can change. If you change this, make sure to update the FNCloud file as well.

# Local port
LOCAL_PORT = 3389 # You can change.

# Initial buffer size
BUFFER_SIZE = 256 * 1024

# Constants for connection speed testing
TEST_DATA_SIZE = 1024 * 1024 # 1 MB
TEST_INTERVAL = 5 # 5 seconds

def forward_data(source_socket, destination_socket):
    try:
        while True:
            # Read data from the source socket
            data = source_socket.recv(BUFFER_SIZE)
            if not data:
                logging.info('Connection closed.')
                break

            # Forward the data to the destination socket
            destination_socket.sendall(data)

    except ConnectionResetError as e:
        logging.error(f'Connection reset by the peer: {e}')
    finally:
        source_socket.close()
        destination_socket.close()

def test_connection_speed(agent_socket):
    start_time = time.time()
    agent_socket.sendall(b'x' * TEST_DATA_SIZE)
    end_time = time.time()
    elapsed_time = end_time - start_time
    connection_speed = TEST_DATA_SIZE / elapsed_time
    adjust_buffer_size(connection_speed)

def adjust_buffer_size(connection_speed):
    global BUFFER_SIZE
    if connection_speed > 10 * 1024 * 1024: # 10 Mbps
        BUFFER_SIZE = 4 * 1024 * 1024 # 4 MB
    elif connection_speed > 5 * 1024 * 1024: # 5 Mbps
        BUFFER_SIZE = 2 * 1024 * 1024 # 2 MB
    elif connection_speed > 1 * 1024 * 1024: # 1 Mbps
        BUFFER_SIZE = 1 * 1024 * 1024 # 1 MB
    else:
        BUFFER_SIZE = 256 * 1024 # 256 KB

    logging.info(f'Buffer size adjusted to {BUFFER_SIZE} bytes based on connection speed {connection_speed:.2f} bytes/s.')

def handle_connection(agent_socket):
    # Create a local socket to connect to RDP service
    local_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        local_socket.connect(('127.0.0.1', LOCAL_PORT))
        logging.info(f'Connected to local RDP service on port {LOCAL_PORT}')
    except Exception as e:
        logging.error(f'Failed to connect to local RDP service: {e}')
        agent_socket.close()
        return

    # Create threads for forwarding data
    forward_thread1 = threading.Thread(target=forward_data, args=(agent_socket, local_socket))
    forward_thread2 = threading.Thread(target=forward_data, args=(local_socket, agent_socket))

    # Start the threads
    forward_thread1.start()
    forward_thread2.start()

    # Wait for threads to finish (not ideal - explained later)
    forward_thread1.join()
    forward_thread2.join()

def stop_agent(agent_socket):
    logging.info("Stopping agent...")
    # Ideally, implement a cleaner shutdown mechanism (e.g., events)
    # This approach might abruptly close sockets causing issues.
    agent_socket.close()

def main():
    while True:
        try:
            # Create the agent socket and connect to the server
            agent_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            agent_socket.connect((SERVER_ADDRESS, SERVER_PORT))
            logging.info(f'Agent connected to server at {SERVER_ADDRESS}:{SERVER_PORT}')

            # Test connection speed periodically
            while True:
                handle_connection(agent_socket)
                test_connection_speed(agent_socket)
                time.sleep(TEST_INTERVAL)

        except Exception as e:
            logging.error(f'Error in main loop: {e}')
            time.sleep(2) # Retry after 5 seconds

if __name__ == "__main__":
    # Keyboard interrupt handling isn't straightforward with threads
    # Consider using a separate process with signal handling for stopping.
    main()
