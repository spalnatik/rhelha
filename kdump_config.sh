#!/bin/bash

pcs stonith create rsc_st_kdump fence_kdump pcmk_reboot_action="off" pcmk_host_list="prod-cl1-0 prod-cl1-1" timeout=30
pcs stonith create rsc_st_kdump fence_kdump pcmk_reboot_action="off" pcmk_host_list="prod-cl1-0 prod-cl1-1"
pcs stonith level add 1 prod-cl1-0 rsc_st_kdump
pcs stonith level add 1 prod-cl1-1 rsc_st_kdump
pcs stonith level add 2 prod-cl1-0 rsc_st_azure
pcs stonith level add 2 prod-cl1-1 rsc_st_azure
pcs stonith level
