<#
        .SYNOPSIS
        This script retrieves a console screenshot of one or more virtual machines.

        .DESCRIPTION
        The script needs four parameters: 
        
        - the name of the VM (name from the inventory)
        - the hostname of a vCenter or ESXi host
        - username, and
        - password

        You can also pipeline a list of VMs to the script.

        History  
        v0.1: Under development
     
        .EXAMPLE
        Get-ScreenshotFromVM -vm testvm -vmhost vcenter -username thomastest -password yoursecretpassword
    
        .NOTES
        Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
        This script is provided 'AS IS' with no warranty expressed or implied. Run at your own risk.

        This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
        International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).

        This script is inspired by "Get-VMScreenshot" by Martin Pugh (@thesurlyadm1n, www.thesurlyadmin.com)
    
        https://community.spiceworks.com/scripts/show/1748-get-vmscreenshot-get-screen-shots-from-the-console-session-of-your-vm-s

        .LINK
        http://www.vcloudnine.de
#>

#Requires -Version 3.0
#Requires -Module VMware.VimAutomation.Core

# Parameter

Param (
    [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true, 
        ValueFromPipelineByPropertyName=$true)]
    [String[]]$VM = "Name of VM",
    [Parameter(Mandatory=$true)]
    [string]$VMhost = "Name of vCenter or ESXi host",
    [string]$Username = "Username",
    [string]$Password = "Password"
)

Begin {
  
    # Variables
  
    $SecString = ConvertTo-SecureString $Password -asplaintext -force
    $Cred = New-Object System.Management.Automation.PSCredential($Username, $SecString)

    # Connect to vCenter
    try {
      
        Connect-VIServer -Server $VMhost -User $Username -Password $Password -ErrorAction stop | Out-Null
        Write-Host -ForegroundColor Green "Successfully connectioned to $VMhost" 
    
}
    catch {

        throw "Connection to $VMhost failed"

    }
}

# Do something

Process {

    Foreach ($Item in $VM) {

        $VMid = (Get-VM -Name $Item).ExtensionData.MoRef.Value
        Invoke-WebRequest -Uri https://$VMhost/screen?id=$VMid -Credential $Cred -OutFile $Pwd\$Item-$(Get-Date -f yyyyMMdd-hhmm).png
        Write-Host -ForegroundColor Green "Console screenshot was saved as $pwd\$Item-$(Get-Date -f yyyyMMdd-hhmm).png"   

    }
}

# Clean up

End {
 
    # Disconnect from vCenter
 
    Disconnect-VIServer -Force -Confirm:$false
    Write-Host -ForegroundColor Green "Successfully disconnected from $VMhost"

}