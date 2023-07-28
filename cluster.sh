#!/bin/bash

timestamp=$(date +"%Y-%m-%d %H:%M:%S")

echo "Script execution started at: $timestamp"

#set -x


vmname1="prod-cl1-0"
vmname2="prod-cl1-1"
rgname="rhel-ha"
offer="RedHat:RHEL-SAP-HA:8.2:latest"
loc="eastus"
sku_size="Standard_D2s_v3"
vnetname="rhel-ha-vnet"
subnetname="ha-subnet"
logfile="ha.log"

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

##if [ -f "./subscriptionID.txt" ]; then
   ##subscriptionID=$(cat password.txt)
##else
  ##  read -s -p "Please enter the subscription id: " subscriptionID
##fi
##

echo ""
date >> "$logfile"

echo "Creating RG $rgname.."
az group create --name "$rgname" --location "$loc" >> "$logfile"

echo "Creating VNET .."
az network vnet create --name "$vnetname" -g "$rgname" --address-prefixes 10.0.0.0/24 --subnet-name "$subnetname" --subnet-prefixes 10.0.0.0/24 >> "$logfile"

echo "Creating First node"
az vm create -g "$rgname" -n "$vmname1" --admin-username "$username" --admin-password "$password" --image "$offer" --vnet-name "$vnetname" --subnet "$subnetname" --public-ip-sku Standard --private-ip-address "10.0.0.6" --no-wait >> "$logfile"

echo "Creating Second node"
az vm create -g "$rgname" -n "$vmname2" --admin-username "$username" --admin-password "$password" --image $offer --vnet-name "$vnetname" --subnet "$subnetname" --public-ip-sku Standard --private-ip-address "10.0.0.7" >> "$logfile"

echo "Installing RHEL AD ON on both the nodes"

az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/install.sh"],"commandToExecute": "./install.sh"}' >> $logfile >> $logfile

    az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname2 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/install.sh"],"commandToExecute": "./install.sh"}' >> $logfile >> $logfile


echo " Creating Pacemaker cluster on node1"

az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/createpc.sh"],"commandToExecute": "./createpc.sh"}' >> $logfile >> $logfile


#subscriptionID=`az group show --name "rhel-ha" --query "id"|cut -d / -f 3`

echo "Create a custom role for the fence agent"
# Set the URL of the custom role JSON in a variable
role_definition_url="https://raw.githubusercontent.com/spalnatik/rhelha/main/customrole.json" >> $logfile

# Download the JSON file from the URL and save it as a local file
curl -o customrole.json $role_definition_url >> $logfile 

# Get the subscription ID and save it as a variable
subscriptionID=$(az group show --name "rhel-ha" --query "id" --output tsv | cut -d '/' -f 3) >> $logfile

# Replace the placeholder "$subscriptionID" in the local customrole.json file with the actual subscription ID
sed -i "s/\$subscriptionID/$subscriptionID/g" customrole.json >> $logfile

echo "update custom role"
# Create the custom role using the modified JSON file
az role definition create --role-definition customrole.json >> $logfile

echo "add role assignment to node1"

spID=$(az resource list  --resource-group "rhel-ha" -n "prod-cl1-0" --query [*].identity.principalId --out tsv) >> $logfile

az role assignment create --assignee $spID --role 'RH Fence Agent Role' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-0 >> $logfile

az role assignment create --assignee $spID --role 'RH Fence Agent Role' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-1 >> $logfile

echo "role assignment to node2"

spID1=$(az resource list  --resource-group "rhel-ha" -n "prod-cl1-1" --query [*].identity.principalId --out tsv) >> $logfile

az role assignment create --assignee $spID1 --role 'RH Fence Agent Role' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-0 >> $logfile

az role assignment create --assignee $spID1 --role 'RH Fence Agent Role' --scope /subscriptions/$subscriptionID/resourceGroups/$rgname/providers/Microsoft.Compute/virtualMachines/prod-cl1-1 >> $logfile

sleep 120

echo "creting fecing devices"

export rgname
export subscriptionID

# Set the VM extension
az vm extension set \
    --resource-group $rgname \
    --vm-name $vmname1 \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/spalnatik/rhelha/main/fenceconfig.sh"],"commandToExecute": "./fenceconfig.sh"}' >> $logfile


