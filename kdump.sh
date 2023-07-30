#!/bin/bash

# Check if kdump is already installed
if yum list installed | grep -q "^kexec-tools\."; then
    echo "kdump is already installed."
else
    echo "kdump is not installed. Installing..."
    sudo yum install -y kexec-tools
    echo "kdump has been installed."
fi

# Check if kdump service is enabled and running
if systemctl is-enabled kdump.service &> /dev/null; then
    echo "kdump service is enabled."
else
    echo "kdump service is not enabled. Enabling..."
    sudo systemctl enable kdump.service
    echo "kdump service has been enabled."
fi

if systemctl is-active kdump.service &> /dev/null; then
    echo "kdump service is running."
else
    echo "kdump service is not running. Starting..."
    sudo systemctl start kdump.service
    echo "kdump service has been started."
fi

echo "install fence_kdump agent"
yum install fence-agents-kdump
