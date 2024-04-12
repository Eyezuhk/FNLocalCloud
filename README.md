#  <img src="https://github.com/Eyezuhk/FNLocalCloud/releases/download/1.2.1/FNLocalCloud.png" alt="FNLocalCloud" width="70" height="70" style="display: inline;">     FNLocalCloud
![Environment](https://img.shields.io/badge/Windows-Xp,%20Vista,%207,%208,%2010,%2011-brightgreen.svg)
![License](https://img.shields.io/github/license/Eyezuhk/FNLocalCloud)
[![Release](https://img.shields.io/github/release/Eyezuhk/FNLocalCloud)](https://github.com/Eyezuhk/FNLocalCloud/releases)
[![Downloads](https://img.shields.io/github/downloads/Eyezuhk/FNLocalCloud/latest/total.svg?color=green)](https://github.com/Eyezuhk/FNLocalCloud/releases)
[![TotalDownloads](https://img.shields.io/github/downloads/Eyezuhk/FNLocalCloud/total.svg?color=brightgreen)](https://github.com/Eyezuhk/FNLocalCloud)


## Description

FNLocalCloud is a tool that facilitates the exposure of local services using a private cloud server. Offering a direct connection between the local service and the cloud, it eliminates the dependency on third-party solutions like ngrok. With an intuitive interface, it simplifies setup and ensures continuous access to applications and services. It's an ideal choice for development, testing, and project demonstrations, enabling efficient and secure sharing and collaboration.

## Main Features
- Reverse TCP Proxy

## How to Use
To set up and use FNCloud, follow these steps on Linux:

1. **Download the Setup Script**:

   Download and run as root or sudo the `setup_fncloud.sh` script from the repository.
   The setup script will prompt you to enter the port numbers for the agent and client.

   ```bash
   wget https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/setup_fncloud.sh
   sudo chmod +x setup_fncloud.sh
   sudo ./setup_fncloud.sh
   ```

## Downloading and Running the FNLocal Agent

You can download and run the FNLocal agent effortlessly by executing the following command as an administrator:

```bash
curl -o "%USERPROFILE%\Downloads\setup_fnlocal.bat" -LJO https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/setup_fnlocal.bat && "%USERPROFILE%\Downloads\setup_fnlocal.bat"
```
This command will prompt you to input the server IP address, server port, local port and protocol. 

It will then create a scheduled task to execute the program automatically when Windows starts.

### Using the FNLocal.py Python File
Ensure you have Python installed on your system.

Download the FNLocal.py file from the repository.

Open a terminal or command prompt and navigate to the directory where the FNLocal.py file is located.

Run the FNLocal agent by executing the command:

 ```
python FNLocal.py -sa [Server Address] -sp [Server Port] -lp [Local Port] -bs [Buffer Size] -p [Protocol]
 ```
Here's an example of how you can use the parameters:

 ```
python FNLocal.py -sa 8.8.8.8 -sp 80 -lp 3389 -bs 256 -p RDP
 ```
If you don't provide any parameters, the program will check if there's any saved configuration to start with; if not, it will open a window for you to input the parameters. However, it's important to note that when using parameters, they won't be saved in the JSON configuration file.

## Access Your Services

   Once the FNLocalCloud service and FNLocal is running, you can access your services using the specified ports.

   By default, the agent listens on port 80 and the client listens on port 443.

   ```bash
   your_cloud_ip_adress:client_port EG.: 8.7.6.5:443
   ```

   If you've chosen different ports during setup, use those instead.
   
   Remember to open the chosen ports on your cloud provider.


## Removing FNCloud Service

To remove the FNCloud service, associated files, and firewall rules, follow these steps:

1. Download the Removal Script**: Download the remove_fncloud.sh script from the repository.

   ```bash
   wget https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/remove_fncloud.sh
   chmod +x remove_fncloud.sh
   sudo ./remove_fncloud.sh
   ```
This script will prompt you to enter the port numbers for the agent and client if they were changed during setup. It will then validate the input and remove the FNCloud service, associated files, and firewall rules accordingly.

   
## Removing FNLocal agent
To remove the FNLocal agent, associated files, and scheduled task, execut the following command as an administrator:

```
curl -o "%USERPROFILE%\Downloads\remove_fnlocal.bat" -LJO https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/remove_fnlocal.bat && "%USERPROFILE%\Downloads\remove_fnlocal.bat"
```

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
