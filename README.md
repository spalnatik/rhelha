# rhelha

************* ****version 2.0**** *************

I am sharing the updated cluster_v2.sh script (Version 2.0) which now includes new configurations.

![image](https://github.com/spalnatik/rhelha/assets/139609488/4a4e9f40-2d35-4c17-b89d-faf505278ba9)


**Setting up Pacemaker on Red Hat Enterprise Linux in Azure**

  The script performs the steps outlined in the provided documentation:
 
Setting up Pacemaker on RHEL in Azure | Microsoft Learn URL: https://learn.microsoft.com/en-us/azure/sap/workloads/high-availability-guide-rhel-pacemaker?tabs=spn

Azure SAP Pacemaker MSI SPN (microsoft.com) https://techcommunity.microsoft.com/t5/running-sap-applications-on-the/sap-on-azure-high-availability-change-from-spn-to-msi-for/ba-p/3609278
 
**Usage:**
 
**The script will do the following:**
 
-	It will ask user to provide the username and password, which will be used for accessing the cluster nodes.
-	Create resource group, VNET and 2 VM’s.
-	By default it uses redhat 8.2 for SAP( RedHat:RHEL-SAP-HA:8.2:latest), you can use any other sap image by adding the option -i and image Urn.
Ex:
./cluster_v2.sh -i RedHat:RHEL-SAP-HA:8_6:latest
-	Starting a custom script extension to configure:
  -	Install cluster packages, configure firewall rules and start the pacemaker service on both the nodes.
  -	Configure/create pacemaker cluster on node1.
  -	Create fencing device using Managed identity.
  -	Configuring fence_kdump on both nodes.
-	Updating NSGs with public IP and allowing ssh access. 
-	Script takes approximately 10-15 minutes to deploy the cluster.
 
Tools required to run it:
-	WSL (windows subsystem for Linux) or any Linux system.
-	Azure CLI installed on the machine and already logged in.
 
limitations:
-	The script has been written for RHEL on SAP images for both RHEL 7 and 8 versions. However, there are repository issues with RHEL 7 images, and the cluster packages couldn't be installed. Therefore, please use RHEL 8 images for now, and I will update you once the issue is fixed for RHEL 7.
-	The VM names cannot be changed because there is a dependency on the scripts that configure the cluster based on the hostname.
