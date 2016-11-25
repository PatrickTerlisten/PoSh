<#
.SYNOPSIS
Distribute-VMs
    
.DESCRIPTION
This script tries to distribute VMs equally in a vSphere cluster without DRS.
    
.EXAMPLE
Distribute-VMs
    
.NOTES
Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
This script is provided "AS IS" with no warranty expressed or implied. Run at your own risk.
    
.LINK
http://www.vcloudnine.de
#>

#Requires -Version 3.0
#Requires -Module VMware.VimAutomation.Core

### Getting parameters from commandline

param
(
  [String]
  [Parameter(Mandatory, Position=0)]
  $cluster
)

### Check if DRS is disbaled
# check VMware DRS Status

### Check if vMotion is available

### Check hosts
# check number of hosts
# check amount of memory per host

### check VMs
# check number of VMs
# check memory per VMs

# distribute VMs