#!/bin/bash

#Create Pacemaker cluster

sudo echo "abc@12345678" | pcs cluster auth prod-cl1-0 prod-cl1-1 -u hacluster
sudo pcs cluster setup --name nw1-azr prod-cl1-0 prod-cl1-1 --token 30000
sudo pcs cluster start --all

sudo pcs quorum expected-votes 2

sudo pcs property set concurrent-fencing=true
