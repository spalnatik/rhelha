#!/bin/bash
pcs resource create vip IPaddr2 ip="10.0.0.13" --group  g-azure
pcs resource create lb azure-lb port=61000 --group g-azure
