# ISPConfig Kickstarter (ispckickstarter)
This is an ISPConfig installer (bash-script) which will make a fully fledged webserver out of a fresh debian jessie based linux machine. You can configure it by simple replacing some variables in the configuration file and it will run completely unattended.

**Be warned: THIS SCRIPT IS VERY EXPERIMENTAL!**

DO NOT USE IT in production environments or if you don't know how to solve problems related to debian or webservers in general. Use it at your own risk!

*My advice: try it in an virtual environment first.*

## Preparation
You need to configure a static IP-address before running this script and install the required packages: `dnsutils` and `locate`.

Download the following files (same directory):
- ispckickstarter.sh (the ISPConfig-installer)
- ispckickstarter.conf (the configuration file)
- [xbi.lib](https://github.com/sonority/xbi) (the installer "library")

## Installation
- Edit the configuration file `ispckickstarter.conf` and replace the base variables with your own values
- Make `ispckickstarter.sh` executable with: `chmod +x ispckickstarter.sh`
- Run the following command as root and go for a coffee: `./ispckickstarter.sh`

## Notes
- If something goes wrong, you can check the file `ispckickstarter.log` where all the tasks and console-output is stored.
- The installer will autogenerate the required passwords and writes them into `ispckickstarter.pwd` during the installation.
- The roundcube-installer is currently not available (it is not available in debian jessie right now), so you have to install it manually. 
