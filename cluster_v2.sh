#!/bin/bash

timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "Script execution started at: $timestamp"

#set -x


vmname1="prod-cl1-0"
vmname2="prod-cl1-1"
rgname="rhel-ha"
asname="rhelhaset"
offer="RedHat:RHEL-SAP-HA:8.2:latest"
loc="eastus"
sku_size="Standard_D2s_v3"
vnetname="rhel-ha-vnet"
subnetname="ha-subnet"
logfile="ha.log"
lbname="rhel-ha-lb"
frontendip="nw-frontend"
backendpoolname="nw-backend"
probename="nw-hp"

# Parse command line arguments
while getopts "i:" opt; do
  case $opt in
    i) offer=$OPTARG ;;
    *) ;;
  esac
done

echo "Offer: $offer"

if [ -f "./username.txt" ]; then
    username=$(cat username.txt)
else
    read -p "Please enter the username: " username
fi

if [ -f "./password.txt" ]; then
    password=$(cat password.txt)
else
    read -s -p "Please enter the password: " password
fi


echo ""
date >> "$logfile"

echo "Creating RG $rgname.."
az group create --name "$rgname" --location "$loc" >> "$logfile"

echo "Creating availability set .."
az vm availability-set create -n $asname -g $rgname --platform-fault-domain-count 3 --platform-update-domain-count 20 --no-wait >> $logfile

echo "Creating VNET .."
az network vnet create --name "$vnetname" -g "$rgname" --address-prefixes 10.0.0.0/24 --subnet-name "$subnetname" --subnet-prefixes 10.0.0.0/24 >> "$logfile"

echo "Creating load balancer .."
az network lb create --resource-group $rgname --name $lbname --location $loc --backend-pool-name $backendpoolname --frontend-ip-name $frontendip --private-ip-address "10.0.0.13" --sku "Standard" --vnet-name $vnetname --subnet $subnetname --no-wait >> $logfile

echo "Creating First node"
az vm create -g "$rgname" -n "$vmname1" --admin-username "$username" --admin-password "$password" --availability-set $asname --image "$offer" --vnet-name "$vnetname" --subnet "$subnetname" --public-ip-sku Standard --private-ip-address "10.0.0.6" --no-wait >> "$logfile"

echo "Creating Second node"
az vm create -g "$rgname" -n "$vmname2" --admin-username "$username" --admin-password "$password" --availability-set $asname --image "$offer" --vnet-name "$vnetname" --subnet "$subnetname" --public-ip-sku Standard --private-ip-address "10.0.0.7" >> "$logfile"

echo "Creating a health probe"
az network lb probe create --lb-name $lbname --resource-group $rgname --name $probename --port 61000 --protocol Tcp >> $logfile

echo "Creating Backend pool configuration"
nic1name1=`az vm show -g $rgname -n $vmname1  --query networkProfile.networkInterfaces[].id -o tsv | cut -d / -f 9`
az network nic ip-config address-pool add --address-pool $backendpoolname --ip-config-name ipconfig$vmname1 --nic-name $nic1name1 --resource-group $rgname --lb-name $lbname  >> $logfile

nic1name2=`az vm show -g $rgname -n $vmname2  --query networkProfile.networkInterfaces[].id -o tsv | cut -d / -f 9` 
az network nic ip-config address-pool add --address-pool $backendpoolname --ip-config-name ipconfig$vmname2 --nic-name $nic1name2 --resource-group $rgname --lb-name $lbname  >> $logfile

echo "Creating load balancing rule .."
az network lb rule create --resource-group $rgname --lb-name $lbname --name "ha-lb-rule" --backend-port 0 --frontend-port 0 \
 --frontend-ip-name $frontendip --backend-pool-name $backendpoolname --protocol All --floating-ip true \
 --idle-timeout 30 --probe-name $probename  >> $logfile
 
echo "Installing RHEL AD ON on both the nodes"

#export password
#export PASSWORD="$password"
az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/rhinstall.sh"],"commandToExecute": "./rhinstall.sh"}' >> $logfile 

    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname2 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/rhinstall.sh"],"commandToExecute": "./rhinstall.sh"}' >> $logfile 


echo " Creating Pacemaker cluster on node1"

version=$(echo "$offer" | grep -oE '([0-9]+[._][0-9]+)')
offersap=$(echo $offer|cut -d ':' -f3)

if [[ "$version" =~ ^7[._][0-9] || "$offersap" =~ ^7[0-9][sap*] ]]; then
    echo "The offer is rhel7 image"
    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/pc7.sh"],"commandToExecute": "./pc7.sh"}' >> $logfile >> $logfile

elif [[ "$version" =~ ^[89][._][0-9] || "$offersap" =~ ^[89][0-9][sap*] ]]; then
    echo "The offer is rhel8 image"
    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/createpc.sh"],"commandToExecute": "./createpc.sh"}' >> $logfile >> $logfile

else
    echo "The offer version is not in the 7.x or 8.x or 9.x"
    # Add your desired action here for other versions (if needed)
fi

if [[ "$version" =~ ^9[._][0-9] || "$offersap" =~ ^9[0-9][sap*] ]]; then
az vm run-command invoke   --resource-group $rgname   --name $vmname1   --command-id RunShellScript   --scripts "sudo yum install -y resource-agents-cloud"  >> $logfile
az vm run-command invoke   --resource-group $rgname   --name $vmname2   --command-id RunShellScript   --scripts "sudo yum install -y resource-agents-cloud"  >> $logfile
fi

#subscriptionID=`az group show --name "rhel-ha" --query "id"|cut -d / -f 3`

#echo "Create a custom role for the fence agent"
# Set the URL of the custom role JSON in a variable
#role_definition_url="https://raw.githubusercontent.com/spalnatik/rhelha/main/customrole.json" >> $logfile

# Download the JSON file from the URL and save it as a local file
#curl -o customrole.json $role_definition_url >> $logfile 

# Get the subscription ID and save it as a variable
subscriptionID=$(az group show --name "rhel-ha" --query "id" --output tsv | cut -d '/' -f 3) >> $logfile

# Replace the placeholder "$subscriptionID" in the local customrole.json file with the actual subscription ID
#sed -i "s/\$subscriptionID/$subscriptionID/g" customrole.json >> $logfile

#echo "update custom role"
# Create the custom role using the modified JSON file
#az role definition create --role-definition customrole.json >> $logfile

echo "add role assignment to node1"

spID=$(az resource list  --resource-group "rhel-ha" -n "prod-cl1-0" --query [*].identity.principalId --out tsv) >> $logfile

az role assignment create --assignee $spID --role 'Virtual Machine Contributor' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-0 >> $logfile

az role assignment create --assignee $spID --role 'Virtual Machine Contributor' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-1 >> $logfile

echo "role assignment to node2"

spID1=$(az resource list  --resource-group "rhel-ha" -n "prod-cl1-1" --query [*].identity.principalId --out tsv) >> $logfile

az role assignment create --assignee $spID1 --role 'Virtual Machine Contributor' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-0 >> $logfile

az role assignment create --assignee $spID1 --role 'Virtual Machine Contributor' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-1 >> $logfile

#sleep 120

echo "creating fecing devices"

export rgname
export subscriptionID
#export password

if [[ "$version" =~ ^7[._][0-9] || "$offersap" =~ ^7[0-9][sap*] ]]; then
    echo "The offer is rhel7 image"
    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/fc7.sh"],"commandToExecute": "./fc7.sh"}' >> $logfile
   
elif [[ "$version" =~ ^[89][._][0-9] || "$offersap" =~ ^[89][0-9][sap*] ]]; then 
    echo "The offer is rhel8 image"
    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/fenceconfig.sh"],"commandToExecute": "./fenceconfig.sh"}' >> $logfile

else
    echo "The offer version is not in the 7.x or 8.x or 9.x"
    # Add your desired action here for other versions (if needed)
fi

# Set the VM extension

echo "configure resource IPaddr2 and azure-lb"
az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/resource.sh"],"commandToExecute": "./resource.sh"}' >> $logfile
    
echo "kdump installation on both the nodes"
az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/kdump.sh"],"commandToExecute": "./kdump.sh"}' >> $logfile

az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname2 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/kdump.sh"],"commandToExecute": "./kdump.sh"}' >> $logfile 

echo "config kdump on node1"

az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/kdump_config.sh"],"commandToExecute": "./kdump_config.sh"}' >> $logfile

echo " restarting kdump service on both nodes"

az vm run-command invoke   --resource-group $rgname   --name $vmname1   --command-id RunShellScript   --scripts "firewall-cmd --add-port=7410/udp;firewall-cmd --add-port=7410/udp --permanent;systemctl restart kdump" >> $logfile

az vm run-command invoke   --resource-group $rgname   --name $vmname2   --command-id RunShellScript   --scripts "firewall-cmd --add-port=7410/udp;firewall-cmd --add-port=7410/udp --permanent;systemctl restart kdump" >> $logfile

echo 'Updating NSGs with public IP and allowing ssh access from that IP'
my_pip=`curl ifconfig.io`
nsg_list=`az network nsg list -g $rgname  --query [].name -o tsv`
for i in $nsg_list
do
	az network nsg rule create -g $rgname --nsg-name $i -n buildInfraRule --priority 100 --source-address-prefixes $my_pip  --destination-port-ranges 22 --access Allow --protocol Tcp >> $logfile
done

end_time=$(date +"%Y-%m-%d %H:%M:%S")

echo "Script execution completed at: $end_time"

