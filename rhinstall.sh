#!/bin/bash

#Install RHEL HA Add-On

# Check if the OS is Red Hat 7.x
if grep -q 'Red Hat Enterprise Linux Server release 7' /etc/redhat-release; then
    echo "Detected Red Hat 7.x. Installing rhui-azure-* packages..."
    
    # Execute the command to install rhui-azure-* packages
    sudo yum install --disablerepo='*' --enablerepo='*microsoft*' 'rhui-azure-*' -y

    echo "Installation completed."
fi


sudo yum install -y pcs pacemaker fence-agents-azure-arm nmap-ncat

# Check the version of the Azure Fence Agent

sudo yum info fence-agents-azure-arm

#Insert the following lines to /etc/hosts. Change the IP address and hostname to match your environment

echo '# IP address of the first cluster node
10.0.0.6 prod-cl1-0
# IP address of the second cluster node
10.0.0.7 prod-cl1-1' | sudo tee -a /etc/hosts


#Change hacluster password to the same password

echo "abc@12345678" | sudo passwd --stdin hacluster

#Add firewall rules for pacemaker



sudo firewall-cmd --add-service=high-availability --permanent
sudo firewall-cmd --add-service=high-availability


#Enable basic cluster services


sudo systemctl start pcsd.service
sudo systemctl enable pcsd.service
