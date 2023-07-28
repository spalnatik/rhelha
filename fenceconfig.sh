sudo pcs stonith create rsc_st_azure fence_azure_arm msi=true resourceGroup="$rgname" subscriptionId="$subscriptionID" power_timeout=240 pcmk_reboot_timeout=900 pcmk_monitor_timeout=120 pcmk_monitor_retries=4 pcmk_action_limit=3 pcmk_delay_max=15 op monitor interval=3600
sudo pcs property set stonith-enabled=true
