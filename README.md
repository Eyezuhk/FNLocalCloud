# FNLocalCloud 
<img src="https://github.com/Eyezuhk/FNLocalCloud/releases/download/v1.0.0/FNLocalCloud.png" alt="FNLocalCloud" width="115" height="115" style="display: inline;">  

![Environment](https://img.shields.io/badge/Windows-Vista,%207,%208,%2010,%2011-brightgreen.svg)
![License](https://img.shields.io/github/license/Eyezuhk/FNLocalCloud)
[![Release](https://img.shields.io/github/release/Eyezuhk/FNLocalCloud)](https://github.com/Eyezuhk/FNLocalCloud/releases)
[![Downloads](https://img.shields.io/github/downloads/Eyezuhk/FNLocalCloud/latest/total.svg?color=green)](https://github.com/Eyezuhk/FNLocalCloud/releases)
[![TotalDownloads](https://img.shields.io/github/downloads/Eyezuhk/FNLocalCloud/total.svg?color=brightgreen)](https://github.com/Eyezuhk/FNLocalCloud)

## Description

FNLocalCloud is a tool that facilitates the exposure of local services using a private cloud server. Offering a direct connection between the local service and the cloud, it eliminates the dependency on third-party solutions like ngrok. With an intuitive interface, it simplifies setup and ensures continuous access to applications and services. It's an ideal choice for development, testing, and project demonstrations, enabling efficient and secure sharing and collaboration.

## Main Features
- TCP Proxy

## How to Use
To set up and use FNCloud, follow these steps on Ubuntu:

1. **Download the Setup Script**:

   Download the `setup_fncloud.sh` script from the repository.

   ```bash
   wget https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/setup_fncloud.sh

2. **Run the Setup Script**: 

    Execute the setup script with root privileges.
   The setup script will prompt you to enter the port numbers for the agent and client.

   If you don't provide any input, it will use default values (80 for the agent port and 443 for the client port).  

   ```bash
   sudo chmod +x setup_fncloud.sh
   sudo ./setup_fncloud.sh
   ```
   
4. Access Your Services

   Once the FNLocalCloud service is running, you can access your services using the specified ports.

   By default, the agent listens on port 80 and the client listens on port 443.

   If you've chosen different ports during setup, use those instead.
   
   Remember to open the chosen ports on your cloud provider.

### Downloading and Running the FNLocal Agent

You can download and run the FNLocal agent in two different ways:

#### Using the FNLocal.py Python File

1. Ensure you have Python installed on your system.
2. Download the FNLocal.py file from the repository.
3. Open a terminal or command prompt and navigate to the directory where the FNLocal.py file is located.
4. Run the FNLocal agent by executing the command:

#### Running the Portable Executable

If you're on Windows and don't have Python installed, you can simply download and run the portable executable:

1. Download the FNLocal.exe file from [here](https://github.com/Eyezuhk/FNLocalCloud/releases/download/v1.0.0/FNLocal.exe).

2. Extract the contents of the FNLocal.zip file to a location on your system.

3. Navigate to the extracted directory and run the portable executable to start the FNLocal agent.

Make sure to open any necessary ports on your firewall to allow connections to the FNLocal agent.

## Removing FNCloud Service

To remove the FNCloud service, associated files, and firewall rules, follow these steps:

1. Download the Removal Script**: Download the remove_fncloud.sh script from the repository.

   ```bash
   wget https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/remove_fncloud.sh
   ```
   
2. Make the Script Executable: Make the script executable with the following command:

   ```bash
   chmod +x remove_fncloud.sh
   ```

3. Execute the Script: Execute the script with root privileges using the following command:

   ```bash
   sudo ./remove_fncloud.sh
   ```

This script will prompt you to enter the port numbers for the agent and client if they were changed during setup. It will then validate the input and remove the FNCloud service, associated files, and firewall rules accordingly.

## Authors
Eyezuhk - https://www.linkedin.com/in/isaacfn/

## Future Improvements
- Support for multiple clients
- Encryption
- Authentication
- Security Tests

## Acknowledgments
Claude.ai <3

## License
GNU General Public License v3.0 (GNU GPLv3)
