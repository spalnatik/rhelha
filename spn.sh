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
    # Run following command if you are setting up fence agent on (two-node cluster and pacemaker version greater than 2.0.4-6.el8) OR (HANA scale out)
    sudo pcs stonith create rsc_st_azure fence_azure_arm username="620a62b3-d9a9-4b14-95d8-da693c0cf51f" password="TJy8Q~Mu2zGaS5vJ2t2dA.Z-27k47--PoDT3kb-q" resourceGroup="$rgname" tenantId="72f988bf-86f1-41af-91ab-2d7cd011db47" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 op monitor interval=3600       
else
    sudo pcs stonith create rsc_st_azure fence_azure_arm username="620a62b3-d9a9-4b14-95d8-da693c0cf51f" password="TJy8Q~Mu2zGaS5vJ2t2dA.Z-27k47--PoDT3kb-q" resourceGroup="$rgname" tenantId="72f988bf-86f1-41af-91ab-2d7cd011db47" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
fi


sudo pcs property set stonith-enabled=true


