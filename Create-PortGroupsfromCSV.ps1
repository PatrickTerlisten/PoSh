<#
        .SYNOPSIS
        This script creates multiple port groups on a vSphere Standard Switch.

        .DESCRIPTION
        The script needs four parameters: 
        
        - a comma-separated list of hosts,
        - the IP or FQDN of the vCenter
        - the name of the vSwitch at which the port groups should be created
        - the input file (CSV file)

        Please use "," as delimiter in the CSV file.

        History  
        v0.1: Under development
     
        .EXAMPLE
        Create-PortGroupsfromCSV -hosts host1,host2 -vCenter vCenter -vswitch vSwitch1 -inputfile c:\temp\portgroups.csv
    
        .NOTES
        Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
        This script is provided 'AS IS' with no warranty expressed or implied. Run at your own risk.

        This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
        International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).

        .LINK
        http://www.vcloudnine.de
#>

#Requires -Version 3.0
#Requires -Module VMware.VimAutomation.Core

# Paramter

Param (
    [Parameter(Mandatory = $true)]
    [string[]]$Hosts = "Comma-separated list of one or more hosts.",
    [string]$vCenter = "FQDN or IP address of the vCenter server",
    [string]$vSwitch = "vSwitch at which the port groups should be created",
    [string]$Inputfile = "CSV file with the input values"
)

# Connect to vCenter

try {
   
    Connect-VIServer -Server $vCenter -ErrorAction stop | Out-Null       
    Write-Host -ForegroundColor Green "Successfully connectioned to $vCenter" 

}
catch {

    throw "Connection to $vCenter failed"

}

# Import input data

$Inputdata = Import-Csv -Path $Inputfile

# Create the port groups

foreach ($VMhost in $Hosts) {

    Write-Host `n
    Write-Host -ForegroundColor Green "Creating port on $VMhost"

    foreach ($Inputtuple in $Inputdata) {

        Get-VirtualSwitch -Name $vSwitch -VMHost $VMhost | New-VirtualPortGroup -Name $Inputtuple.portgroupname -VLanId $Inputtuple.vlanid

    }
}

# Clean up

Disconnect-VIServer -Force -Confirm:$false
Write-Host -ForegroundColor Green "Successfully disconnected from $vCenter"