#!/bin/bash

clientid=$1
clientsecret=$2
rgname=$3
subscriptionID=$4

sudo pcs property set stonith-timeout=900
sudo pcs stonith create rsc_st_azure fence_azure_arm login="$clientid" password="$clientsecret" resourceGroup="$rgname" tenantId="72f988bf-86f1-41af-91ab-2d7cd011db47" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
sudo pcs property set stonith-enabled=true
