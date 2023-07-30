#!/bin/bash

#Create Pacemaker cluster
PASSWORD=$PASSWORD

echo "$PASSWORD" | pcs host auth prod-cl1-0 prod-cl1-1 -u hacluster
sudo pcs cluster setup nw1-azr prod-cl1-0 prod-cl1-1 totem token=30000
sudo pcs cluster start --all

sudo pcs quorum expected-votes 2

sudo pcs property set concurrent-fencing=true
