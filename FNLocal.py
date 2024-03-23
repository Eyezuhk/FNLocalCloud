import tkinter as tk
from tkinter import ttk, filedialog
import socket
import logging
import threading
import time
import os
import json
import sys

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Initial buffer size
BUFFER_SIZE = 256 * 1024

# Constants for connection speed testing
TEST_DATA_SIZE = 1024 * 1024  # 1 MB
TEST_INTERVAL = 5  # 5 seconds

CONFIG_FILE = 'fnlocal_config.json'

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
    if connection_speed > 10 * 1024 * 1024:  # 10 Mbps
        BUFFER_SIZE = 4 * 1024 * 1024  # 4 MB
    elif connection_speed > 5 * 1024 * 1024:  # 5 Mbps
        BUFFER_SIZE = 2 * 1024 * 1024  # 2 MB
    elif connection_speed > 1 * 1024 * 1024:  # 1 Mbps
        BUFFER_SIZE = 1 * 1024 * 1024  # 1 MB
    else:
        BUFFER_SIZE = 256 * 1024  # 256 KB

    logging.info(f'Buffer size adjusted to {BUFFER_SIZE // 1024} KB based on connection speed {connection_speed:.2f} bytes/s.')

def handle_connection(agent_socket, local_port):
    # Create a local socket to connect to RDP service
    local_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        local_socket.connect(('127.0.0.1', local_port))
        logging.info(f'Connected to local RDP service on port {local_port}')
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

def main(server_address, server_port, local_port):
    while True:
        try:
            # Create the agent socket and connect to the server
            agent_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            agent_socket.connect((server_address, server_port))
            logging.info(f'Agent connected to server at {server_address}:{server_port}')

            # Test connection speed periodically
            while True:
                handle_connection(agent_socket, local_port)
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

def save_config(server_address, server_port, local_port, buffer_size):
    config = {
        'server_address': server_address,
        'server_port': server_port,
        'local_port': local_port,
        'buffer_size': buffer_size
    }
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f)

# Função para obter os valores inseridos pelo usuário
def get_values():
    server_address = server_address_entry.get() or 'YOUR_SERVER_IP'
    server_port = int(server_port_entry.get() or '80')
    local_port = int(local_port_entry.get() or '3389')
    buffer_size = int(buffer_size_entry.get() or '256')

    global BUFFER_SIZE
    BUFFER_SIZE = buffer_size * 1024  # Buffer size in bytes

    # Exibir os valores selecionados
    print(f"Server Address: {server_address}")
    print(f"Server Port: {server_port}")
    print(f"Local Port: {local_port}")
    print(f"Buffer Size: {BUFFER_SIZE // 1024} KB")

    # Save configuration
    save_config(server_address, server_port, local_port, buffer_size)

    # Start the main loop
    main(server_address, server_port, local_port)

# Criar a janela principal
root = tk.Tk()
root.title("FNCloud Configuration")

# Load configuration
config = load_config()

if config:
    server_address = config.get('server_address', 'YOUR_SERVER_IP')
    server_port = config.get('server_port', 80)
    local_port = config.get('local_port', 3389)
    buffer_size = config.get('buffer_size', 256)

    # Start the main loop with the loaded configuration
    main_thread = threading.Thread(target=main, args=(server_address, server_port, local_port))
    main_thread.start()

    # Create a taskbar icon or minimized window
    if sys.platform.startswith('win'):
        # Create a minimized window on Windows
        root.iconify()
    else:
        # Create a taskbar icon on other platforms
        root.withdraw()
        taskbar_icon = tk.Toplevel(root)
        taskbar_icon.overrideredirect(True)
        taskbar_icon.withdraw()
        taskbar_icon.iconwindow()
        taskbar_icon.deiconify()
else:
    server_address = 'YOUR_SERVER_IP'
    server_port = 80
    local_port = 3389
    buffer_size = 256

# Criar um frame para organizar os widgets
frame = ttk.Frame(root, padding=20)
frame.grid()

# Criar os rótulos e campos de entrada
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

buffer_size_label = ttk.Label(frame, text="Buffer Size (KB):")
buffer_size_label.grid(row=3, column=0, padx=5, pady=5, sticky=tk.W)
buffer_size_entry = ttk.Entry(frame)
buffer_size_entry.insert(tk.END, str(buffer_size))
buffer_size_entry.grid(row=3, column=1, padx=5, pady=5)

# Criar o botão "Apply"
apply_button = ttk.Button(frame, text="Apply", command=get_values)
apply_button.grid(row=4, column=1, padx=5, pady=5, sticky=tk.E)

# Iniciar o loop principal da interface gráfica
root.mainloop()
