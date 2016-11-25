<#
.SYNOPSIS
Set-HAIsolationAddress
    
.DESCRIPTION
This script configures two Isolation Response Addresses for VMware HA.
    
.EXAMPLE
Set-HAIsolationAddress -ip1 192.168.1.1 -ip2 192.168.1.254 -cluster PROD
    
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
  $IP1,

  [String]
  [Parameter(Mandatory, Position=1)]
  $IP2,

  [Parameter(Mandatory, Position=2)]
  $cluster
)

### Check if HA is enabled
# check VMware HA Status

### Check if isolation addresses are already set. If yes, show addresses
# Check for isolation addresses
# Show config, if isolation addresses are configured

### Set das.isolationaddress and das.usedefaultisolationaddress
# das.isolationaddress1, das.isolationaddress2 and das.usedefaultisolationaddress

Write-Output $IP1
Write-Output $IP2
Write-Output $Cluster

### Print summary and exit