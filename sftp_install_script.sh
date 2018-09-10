#!/bin/bash

# Based on: http://www.krizna.com/ubuntu/setup-ftp-server-on-ubuntu-14-04-vsftpd/
sftp_user='someuser'
sftp_passwd='SomePassword'

# IMPORTANT: Edit the values above or comment out the user add code before running.

print_success() { echo -e "\e[32m${@}\e[0m"; }
print_error() { echo -e "\e[31m${@}\e[0m"; }

if [ `whoami` != "root" ] && [ `whoami` != "forge" ] && [ `whoami` != "homestead" ] && [ `whoami` != "vagrant" ];
then
    print_error "You must be root to run this script!"
    exit 1
fi

echo "Updating apt..."
sudo_output=$(sudo bash -c "apt-get update 2>&1; echo $?")
sudo_result=$?
aptget_result=$(echo "${sudo_output}"| tail -1)

echo "${sudo_output}"

# Check results
if [ ${sudo_result} -eq 0 ]; then
    if [ ${aptget_result} -eq 0 ]; then
       print_success "Updated apt."
    else
       print_error "Failed to apt, apt-get error!"
    fi
else
    print_error "Failed to update apt, sudo error!"
    exit 1
fi

echo "Installing VsFTPD package..."
sudo_output=$(sudo bash -c "apt-get -y install vsftpd 2>&1; echo $?")

# Get results.
sudo_result=$?
aptget_result=$(echo "${sudo_output}"| tail -1)

# Show apt-get output.
echo "${sudo_output}"

# Check results
if [ ${sudo_result} -eq 0 ]; then
    if [ ${aptget_result} -eq 0 ]; then
       print_success "Installed VsFTPD."
    else
       print_error "Failed to Install VsFTPD, apt-get error!"
    fi
else
    print_error "Failed to Install VsFTPD, sudo error!"
    exit 1
fi

echo "Installing openssh-server"
sudo_output=$(sudo bash -c "apt-get install openssh-server 2>&1; echo $?")
sudo_result=$?
aptget_result=$(echo "${sudo_output}"| tail -1)
echo "${sudo_output}"

# Check results
if [ ${sudo_result} -eq 0 ]; then
    if [ ${aptget_result} -eq 0 ]; then
       print_success "Installed openssh-server."
    else
       print_error "Failed to install openssh-server, apt-get error!"
    fi
else
    print_error "Failed to install openssh-server, sudo error!"
    exit 1
fi

sshd_config='/etc/ssh/sshd_config'

sudo mv $sshd_config $sshd_config.bak
sudo rm -f $sshd_config

echo "# SSH Config
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
UsePAM yes
Subsystem sftp internal-sftp
Match group ftpaccess
ChrootDirectory %h
AllowTcpForwarding no
ForceCommand internal-sftp
" | sudo tee $sshd_config

echo "Restarting SSH service..."
sudo service ssh restart

echo "Creating user and group..."
sudo groupadd ftpaccess
sudo useradd -m $sftp_user -g ftpaccess -s /usr/sbin/nologin
echo "$sftp_passwd" | sudo passwd $sftp_user

echo "Done! :)"
