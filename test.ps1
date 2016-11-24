<#
.SYNOPSIS
Test.
    
.DESCRIPTION
This is only a test
    
.EXAMPLE
test
    
.NOTES
Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
This script does nothing.

This script is provided "AS IS" with no warranty expressed or implied. Run at your own risk.
    
.LINK
http://www.vcloudnine.de
#>

### Set Parameters ###
# HA Isolationaddresses

$cluster = Get-Cluster -Name YourCluster
$isolationaddress1 = '192.168.100.1'
$isolationaddress2 = '192.168.100.2'

New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress1' -Value $isolationaddress1
New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.isolationaddress1' -Value $isolationaddress2

New-AdvancedSetting -Entity $cluster -Type ClusterHA -Name 'das.usedefaultisolationaddress' -Value false
Once these options are set you have to reconfigure HA and the simplest way I found to do this was to disable and re-enable HA.
Set-Cluster -Cluster $cluster -HAEnabled:$false

Set-Cluster -Cluster $cluster -HAEnabled:$true
