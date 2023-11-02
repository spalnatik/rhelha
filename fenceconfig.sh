#!/bin/bash

rgname=$1
subscriptionID=$2

sudo pcs property set stonith-timeout=900

#!/bin/bash

# Get the pacemaker version
pacemaker_version=$(rpm -q --queryformat "%{VERSION}-%{RELEASE}\n" pacemaker)


# Define the target version to compare against
target_version="2.0.4-6"


# Compare the pacemaker version and target version
if [[ "$pacemaker_version" > "$target_version" ]]; then
    pcs stonith create rsc_st_azure fence_azure_arm msi=true resourceGroup="$rgname" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 op monitor interval=3600       
else
    pcs stonith create rsc_st_azure fence_azure_arm msi=true resourceGroup="$rgname" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
fi


sudo pcs property set stonith-enabled=true
