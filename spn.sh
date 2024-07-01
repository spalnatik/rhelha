#!/bin/bash


clientid=$1
clientsecret=$2
rgname=$3
subscriptionID=$4

sudo pcs property set stonith-timeout=900

#!/bin/bash

# Get the pacemaker version
pacemaker_version=$(rpm -q --queryformat "%{VERSION}-%{RELEASE}\n" pacemaker)


# Define the target version to compare against
target_version="2.0.4-6"


# Compare the pacemaker version and target version
if [[ "$pacemaker_version" > "$target_version" ]]; then
    # Run following command if you are setting up fence agent on (two-node cluster and pacemaker version greater than 2.0.4-6.el8) OR (HANA scale out)
    sudo pcs stonith create rsc_st_azure fence_azure_arm username="$clientid" password="$clientsecret" resourceGroup="$rgname" tenantId="16b3c013-d300-468d-ac64-7eda0820b6d3" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 op monitor interval=3600       
else
    sudo pcs stonith create rsc_st_azure fence_azure_arm username="$clientid" password="$clientsecret" resourceGroup="$rgname" tenantId="16b3c013-d300-468d-ac64-7eda0820b6d3" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
fi


sudo pcs property set stonith-enabled=true


