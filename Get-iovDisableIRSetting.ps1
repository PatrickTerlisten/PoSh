<#
        .SYNOPSIS
        This script checks if the iovDisableIR setting is set to FALSE.

        .DESCRIPTION
        The script checks the current setting of the Intel IOMMU interrupt remapper (iovDisableIR).

        The script needs a single parameter: 
        
        - vSphere Cluster

        History  
        v0.2: Under development
     
        .EXAMPLE
        Get-iovDisableIRSetting -Cluster LAB
    
        .NOTES
        Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
        This script is provided 'AS IS' with no warranty expressed or implied. Run at your own risk.

        This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
        International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).

        ESXi hosts running ESXi 5.5 Patch 10, 6.0 Patch 4, 6.0 U3, or 6.5 may fail with a purple diagnostic screen
        caused by non-maskable-interrupts (NMI) on HPE ProLiant Gen8 Servers.

        Important vendor links:

        ESXi host fails with intermittent NMI PSOD on HP ProLiant Gen8 servers (2149043)
        https://kb.vmware.com/kb/2149043

        Advisory: (Revision) VMware - HPE ProLiant Gen8 Servers running VMware ESXi 5.5 Patch 10, VMware ESXi 6.0 Patch 4,
        or VMware ESXi 6.5 May Experience Purple Screen Of Death (PSOD): LINT1 Motherboard Interrupt
        http://h20564.www2.hpe.com/hpsc/doc/public/display?docId=emr_na-c05392947

        .LINK
        http://www.vcloudnine.de
#>

#Requires -Version 3.0
#Requires -Module VMware.VimAutomation.Core

# Parameter

Param (
    [Parameter(Mandatory = $true)]
    [string]$cluster = "Name of the vSphere Cluster"
)

# Get the ESXi hosts from the given cluster

$Hosts = Get-Cluster $cluster | Get-VMhost

# Create an empty array for the PowerShell object

$Results = @()

# Looping through the VMHosts

$Hosts | ForEach-Object {

    $EsxCliv2 = Get-EsxCli -V2 -VMHost $_
    $Arguments = $EsxCliv2.system.settings.kernel.list.CreateArgs()
    $Arguments.option = "iovDisableIR"
    $Output = $EsxCliv2.system.settings.kernel.list.Invoke($Arguments)

    # Get the vendor and model of the current VMHost

    $Model = $_ | Get-View | Select-Object @{N = 'Model'; E = {$_.Hardware.SystemInfo.Vendor + ' ' + $_.Hardware.SystemInfo.Model}}

    # Properties for the PowerShell object

    $PSOProps = @{
 
        VMHost = $_.name
        Model = $Model.Model
        
        # The value of "Runtime" represents the current active mode of iovDisableIR
        
        iovDisableIR = $Output.Runtime
 
    }

    $Results += New-Object -TypeName psobject -Property $PSOProps
}

# Getting a list of the affected hosts by filtering the output for iovDisableIR = TRUE and server models with "Gen8"

$AffectedHosts = $Results | Where-Object {$_.iovDisableIR -eq 'TRUE' -and $_.Model -like '*Gen8'} | Select-Object VMhost

$Count = ($AffectedHosts).Count

If ($Count -gt 0) {
    
    Write-host `n
    Write-Host -ForegroundColor Red "$Count hosts are affected. Please set iovDisableIR to FALSE on the affected hosts. The following hosts are affected:"
    Write-Host -ForegroundColor Red 'Please execute "esxcli system settings kernel set --setting=iovDisableIR -v FALSE" on each host and reboot the host afterwards.'
    
    $AffectedHosts | Sort-Object VMhost

}

else {

    Write-host `n
    Write-Host -ForegroundColor Green "None of your hosts seeems to be affected."
    Write-host `n

}