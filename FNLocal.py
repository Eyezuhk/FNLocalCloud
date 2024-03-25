import tkinter as tk
from tkinter import ttk
import socket
import logging
import threading
import time
import os
import json
import argparse

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Initial buffer size
BUFFER_SIZE = 256 * 1024

# Constants for connection speed testing
TEST_DATA_SIZE = 1024 * 1024  # 1 MB
TEST_INTERVAL = 5  # 5 seconds

CONFIG_FILE = 'fnlocal_config.json'

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

def test_connection_speed(agent_socket):
    start_time = time.time()
    agent_socket.sendall(b'x' * TEST_DATA_SIZE)
    end_time = time.time()
    elapsed_time = end_time - start_time
    connection_speed = TEST_DATA_SIZE / elapsed_time
    adjust_buffer_size(connection_speed)

def adjust_buffer_size(connection_speed):
    global BUFFER_SIZE
    if connection_speed > 10 * 1024 * 1024:  # 10 Mbps
        BUFFER_SIZE = 4 * 1024 * 1024  # 4 MB
    elif connection_speed > 5 * 1024 * 1024:  # 5 Mbps
        BUFFER_SIZE = 2 * 1024 * 1024  # 2 MB
    elif connection_speed > 1 * 1024 * 1024:  # 1 Mbps
        BUFFER_SIZE = 1 * 1024 * 1024  # 1 MB
    else:
        BUFFER_SIZE = 256 * 1024  # 256 KB

    logging.info(f'Buffer size adjusted to {BUFFER_SIZE // 1024} KB based on connection speed {connection_speed:.2f} bytes/s.')

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

def main(server_address, server_port, local_port, protocol):
    while True:
        try:
            agent_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            agent_socket.connect((server_address, server_port))
            logging.info(f'Agent connected to server at {server_address}:{server_port}')

            while True:
                handle_connection(agent_socket, local_port, protocol)
                test_connection_speed(agent_socket)
                time.sleep(TEST_INTERVAL)

        except Exception as e:
            logging.error(f'Error in main loop: {e}')
            time.sleep(2)  # Retry after 2 seconds

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
        return config
    else:
        return None

def save_config(server_address, server_port, local_port, buffer_size, protocol):
    config = {
        'server_address': server_address,
        'server_port': server_port,
        'local_port': local_port,
        'buffer_size': buffer_size,
        'protocol': protocol
    }
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f)

def get_values(root, server_address_entry, server_port_entry, local_port_entry, buffer_size_entry, protocol_entry):
    server_address = server_address_entry.get() or 'YOUR_SERVER_IP'
    server_port = int(server_port_entry.get() or '80')
    local_port = int(local_port_entry.get() or '3389')
    buffer_size = int(buffer_size_entry.get() or '256')
    protocol = protocol_entry.get() or 'RAW'

    global BUFFER_SIZE
    BUFFER_SIZE = buffer_size * 1024  # Buffer size in bytes

    print(f"Server Address: {server_address}")
    print(f"Server Port: {server_port}")
    print(f"Local Port: {local_port}")
    print(f"Protocol: {protocol}")
    print(f"Buffer Size: {BUFFER_SIZE // 1024} KB")

    save_config(server_address, server_port, local_port, buffer_size, protocol)

    main(server_address, server_port, local_port, protocol)
    root.quit()

def create_gui():
    root = tk.Tk()
    root.title("FNCloud Configuration")

    config = load_config()

    if config:
        server_address = config.get('server_address', 'YOUR_SERVER_IP')
        server_port = config.get('server_port', 80)
        local_port = config.get('local_port', 3389)
        buffer_size = config.get('buffer_size', 256)
        protocol = config.get('protocol', 'RAW')

        global BUFFER_SIZE
        BUFFER_SIZE = buffer_size * 1024  # Buffer size in bytes

        print(f"Server Address: {server_address}")
        print(f"Server Port: {server_port}")
        print(f"Local Port: {local_port}")
        print(f"Protocol: {protocol}")
        print(f"Buffer Size: {BUFFER_SIZE // 1024} KB")

        # Start the main function with the loaded configuration
        main_thread = threading.Thread(target=main, args=(server_address, server_port, local_port, protocol))
        main_thread.start()
    else:
        server_address = 'YOUR_SERVER_IP'
        server_port = 80
        local_port = 3389
        buffer_size = 256
        protocol = 'RAW'

    frame = ttk.Frame(root, padding=20)
    frame.grid()

    server_address_label = ttk.Label(frame, text="Server Address:")
    server_address_label.grid(row=0, column=0, padx=5, pady=5, sticky=tk.W)
    server_address_entry = ttk.Entry(frame)
    server_address_entry.insert(tk.END, server_address)
    server_address_entry.grid(row=0, column=1, padx=5, pady=5)

    server_port_label = ttk.Label(frame, text="Server Port:")
    server_port_label.grid(row=1, column=0, padx=5, pady=5, sticky=tk.W)
    server_port_entry = ttk.Entry(frame)
    server_port_entry.insert(tk.END, str(server_port))
    server_port_entry.grid(row=1, column=1, padx=5, pady=5)

    local_port_label = ttk.Label(frame, text="Local Port:")
    local_port_label.grid(row=2, column=0, padx=5, pady=5, sticky=tk.W)
    local_port_entry = ttk.Entry(frame)
    local_port_entry.insert(tk.END, str(local_port))
    local_port_entry.grid(row=2, column=1, padx=5, pady=5)

    protocol_label = ttk.Label(frame, text="Protocol:")
    protocol_label.grid(row=3, column=0, padx=5, pady=5, sticky=tk.W)
    protocol_entry = ttk.Entry(frame)
    protocol_entry.insert(tk.END, protocol)
    protocol_entry.grid(row=3, column=1, padx=5, pady=5)

    buffer_size_label = ttk.Label(frame, text="Buffer Size (KB):")
    buffer_size_label.grid(row=4, column=0, padx=5, pady=5, sticky=tk.W)
    buffer_size_entry = ttk.Entry(frame)
    buffer_size_entry.insert(tk.END, str(buffer_size))
    buffer_size_entry.grid(row=4, column=1, padx=5, pady=5)

    apply_button = ttk.Button(frame, text="Apply", command=lambda: get_values(root, server_address_entry, server_port_entry, local_port_entry, buffer_size_entry, protocol_entry))
    apply_button.grid(row=5, column=1, padx=5, pady=5, sticky=tk.E)

    root.mainloop()

def parse_args():
    parser = argparse.ArgumentParser(description='FNCloud Configuration Options')
    parser.add_argument('-sa', '--server_address', type=str, help='Server Address')
    parser.add_argument('-sp', '--server_port', type=int, help='Server Port')
    parser.add_argument('-lp', '--local_port', type=int, help='Local Port')
    parser.add_argument('-bs', '--buffer_size', type=int, help='Buffer Size (KB)')
    parser.add_argument('-p', '--protocol', type=str, help='Protocol')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()

    if not any(vars(args).values()):
        config = load_config()
        if config:
            server_address = config.get('server_address')
            server_port = config.get('server_port')
            local_port = config.get('local_port')
            buffer_size = config.get('buffer_size')
            protocol = config.get('protocol')
            main(server_address, server_port, local_port, protocol)
        else:
            create_gui()
    else:
        main(args.server_address, args.server_port, args.local_port, args.protocol)
