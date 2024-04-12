import socket
import logging
import threading
import time
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Initial buffer size
BUFFER_SIZE = 256 * 1024 * 1024 # 256 Mb default

def forward_data(source_socket, destination_socket, protocol):
    try:
        while True:
            data = source_socket.recv(BUFFER_SIZE)
            if not data:
                logging.info('Connection closed.')
                break

            if protocol == 'HTTP':
                # Parse HTTP request
                request = data.decode().split('\r\n', 1)
                method, path, version = request[0].split()
                headers = dict(line.split(': ', 1) for line in request[1].split('\r\n') if line)

                # Forward the request to the local server
                destination_socket.sendall(data)

                # Receive the response
                response = destination_socket.recv(BUFFER_SIZE)

                # Parse the response headers
                headers = response.split(b'\r\n\r\n', 1)
                response_headers = headers[0].decode()
                response_body = headers[1] if len(headers) > 1 else b''

                # Forward the response to the client
                source_socket.sendall(response)
            else:
                # Forward the data to the destination socket
                destination_socket.sendall(data)

    except ConnectionResetError as e:
        logging.error(f'Connection reset by the peer: {e}')
    finally:
        source_socket.close()
        destination_socket.close()

def handle_connection(agent_socket, local_port, protocol):
    local_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        local_socket.connect(('127.0.0.1', local_port))
        logging.info(f'Connected to local {protocol} service on port {local_port}')
    except Exception as e:
        logging.error(f'Failed to connect to local {protocol} service: {e}')
        agent_socket.close()
        return

    forward_thread1 = threading.Thread(target=forward_data, args=(agent_socket, local_socket, protocol))
    forward_thread2 = threading.Thread(target=forward_data, args=(local_socket, agent_socket, protocol))

    forward_thread1.start()
    forward_thread2.start()

    forward_thread1.join()
    forward_thread2.join()

def main(server_address, server_port, local_port, buffer_size, protocol):
    global BUFFER_SIZE
    BUFFER_SIZE = buffer_size  # Buffer size in bytes
    
    while True:
        try:
            agent_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            agent_socket.connect((server_address, server_port))
            logging.info(f'Agent connected to server at {server_address}:{server_port}')
            handle_connection(agent_socket, local_port, protocol)
            #while True:

        except Exception as e:
            logging.error(f'Error in main loop: {e}')
            time.sleep(1)  # Retry after 1 second

def parse_args():
    parser = argparse.ArgumentParser(description='FNCloud Configuration Options')
    parser.add_argument('-sa', '--server_address', type=str, required=True, help='Server Address')
    parser.add_argument('-sp', '--server_port', type=int, required=True, help='Server Port')
    parser.add_argument('-lp', '--local_port', type=int, required=True, help='Local Port')
    parser.add_argument('-bs', '--buffer_size', type=int, required=True, help='Buffer Size (KB)')
    parser.add_argument('-p', '--protocol', type=str, required=True, help='Protocol')
    return parser.parse_args()

main(args.server_address, args.server_port, args.local_port, args.buffer_size, args.protocol)
