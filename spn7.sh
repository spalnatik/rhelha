#!/bin/bash

clientid=$1
clientsecret=$2
rgname=$3
subscriptionID=$4

sudo pcs property set stonith-timeout=900
sudo pcs stonith create rsc_st_azure fence_azure_arm login="$clientid" passwd="$clientsecret" resourceGroup="$rgname" tenantId="16b3c013-d300-468d-ac64-7eda0820b6d3" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
sudo pcs property set stonith-enabled=true
