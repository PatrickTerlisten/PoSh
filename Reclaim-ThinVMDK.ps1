<#
    .SYNOPSIS
    No parameters needed. Just execute the script.

    .DESCRIPTION
    This script uses sdelete to zero-out all disks of a Windows VM. Afterwards, the VM
    is moved between datastores to reclaim zeroed space.

    History
    v1.3: Redesign.
    
    v1.2: Added function to zero-out all disks in a guest VM. WMI is used to fetch a
    list with all local disk (drivetype = 3).
    
    v1.1: The script now skips VMs with Snapshots and ZeroedThick or EagerZeroedThick
    disks
    
    v1.0: Initial version
     
   .EXAMPLE
    Reclaim-ThinVMDK
    
   .NOTES
    Author: Patrick Terlisten, patrick@blazilla.de, Twitter @PTerlisten
    
    This script is provided “AS IS” with no warranty expressed or implied. Run at your own risk.

    This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
    International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).
    
   .LINK
    http://www.vcloudnine.de
#>

### Please change the content of the variables for $PathToSDelete, $VIServer
### $CredFile, $Username, $DstDS, $DstDSHost and $ClusterName according to your environment.

# Path to SDelete and command to exectue. Please make sure that you use the latest version 1.61!
$PathToSDelete ='C:\Windows\sdelete.exe'
$SDeleteCommandLine = 'sdelete -q -z'

# vCenter Server
# I recommend to create a new VICredentialStoreItem and use this to connect to the vCenter Server
$VIServer = 'vcenter.domain.tld'

# To create an encrypted password file, execute the following command
# Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File securestring.txt
# Fill $CredFile with path to securesting.txt. Please make sure that you create the
# $CredFile with the user that is running this script.
$CredFile = 'C:\PATH\TO\securestring.txt'
$Username = 'DOMAIN\USERNAME'
$Password = (Get-Content $CredFile | ConvertTo-SecureString)
$Cred = New-Object System.Management.Automation.PSCredential ($Username, $Password)

# Set destination datastore. Can be a local or shared VMFS datastore.
# If a local datastore is used, $DstDSHost must be set. In case of a shared datastore
# set $DstDSHost to $null.
$DstDS = 'DATASTORE-NAME'
$DstDSHost = 'esx-host.domain.tld'
#$DstDSHost = $null

# Name of vSphere Cluster
$ClusterName = 'VSPHERE-CLUSTER'

# Connect to vCenter Server. VICredentialStoreItem is used for connection. Otherwise change
# parameters and add -User -Password
Write-Host "`n"
Write-Host "Connecting to vCenter Server $VIServer" -ForegroundColor Green
Connect-VIServer $VIServer | Out-Null

# Build an array with all Windows VMs
$SrcVM = (Get-Cluster $ClusterName | Get-VM | Where-Object { $_.Guest.OSFullName -like '*Windows*' })

# Debug: Run only for specific VM
#$SrcVM = (Get-VM | Where { $_.Name -like "vmname" })

# For every object in the array...
$SrcVM | ForEach-Object {
    
    # Tell me what you're doing..
    Write-Host "`n"
    Write-Host "### Processing VM $_ ###" -ForegroundColor Green
    
    # Check for ZeroedThick and EagerZeroedThick disks
    $DiskFormat = ((Get-HardDisk $_).StorageFormat | Select-Object -uniq)
    
    If ( $DiskFormat -like '*Thick*' ) {
        
        Write-Host "`n"
        Write-Host "ERROR: At least one disk on VM $_ is of type ZeroedThick or EagerZeroedThick. Skipping this VM" -ForegroundColor Red
        
    }
    
    else {
        
        # Check for Snapshots
        $NumberOfSnaps = (Get-VM $_ | Get-Snapshot)
        
        If ($NumberOfSnaps.Count -gt 0) {
            
            Write-Host "`n"
            Write-Host "ERROR: VM $_ has at least one active snaphost. Skipping this VM" -ForegroundColor Red
            
        }
        
        elseif ($NumberOfSnaps.Count -eq 0) {
            
            # Set source datastore
            $SrcDS = ((Get-HardDisk $_).Filename).Split('[')[1].Split(']')[0]
            
            # Set source host
            $SrcHost = (Get-VM $_ | Get-VMHost).name
            
            # Initiate new PSSession
            $RemotePSSession = New-PSSession -ComputerName $_.Guest.HostName -Credential $Cred
            
            # Tell me what you're doing...
            Write-Host "Starting to zero-out volumes on VM $_. Calling Invoke-Command to run SDelete. To be honest: This can take some time... Check the Task Manager inside the VM for a running sdelete.exe process." -ForegroundColor Green
            
            # Test if SDelete exist. If yes, zero-out all disks
            $ExitCodeInvokeCommand = Invoke-Command -Session $RemotePSSession -ArgumentList $PathToSDelete, $SDeleteCommandLine -ScriptBlock {
                
                # This is the sdelete commandline which is used in the GetWmiObject invocation
                $CommandlineInGuest = $args[1]

                # Test for SDelete and run SDelete
                If (Test-Path $args[0]) {

                    Get-WmiObject win32_logicaldisk| Where-Object { $_.drivetype -eq 3 } | ForEach-Object { cmd.exe /c $CommandlineInGuest $_.name } | Out-Null

                    $ErrorCode = 0
                    
                } Else {
                    
                    $ErrorCode = 1
                    
                }; $ErrorCode
                
            }
            
            # Remove PSSession
            Remove-PSSession $_.Guest.HostName
            
            # If SDelete was found and zero-out has completed, move VM to $DstDS and then back to $SrcDS and $SrcHost
            
            If ($ExitCodeInvokeCommand -eq 0) {
                
                # Move-VM is used to SvMotion the VM to the destination datastore using the original DiskStorageFormat (should be always thin)
                # If a local datastore is used as destination, the VM is moved to the host with the local datastore an then later back to its source host
                
                If ($DstDSHost -eq $Null) {
                    
                    Write-Host "Exitcode of Invoke-Command was $ExitCodeInvokeCommand. Everything seems to be fine. Moving VM $_ to $DstDS." -ForegroundColor Green
                    Move-VM -VM $_ -Datastore $DstDS -DiskStorageFormat $DiskFormat | Out-Null

                } Else {
                    
                    Write-Host "Exitcode of Invoke-Command was $ExitCodeInvokeCommand. Everything seems to be fine. Moving VM $_ to $DstDS on $DstDSHost." -ForegroundColor Green
                    Move-VM -VM $_ -Destination $DstDSHost -Datastore $DstDS -DiskStorageFormat $DiskFormat | Out-Null
                    
                }
                
                # Move-VM is used to SvMotion the VM back to its original datastore using the original DiskStorageFormat
                Write-Host "Moving VM back to $SrcDS on $SrcHost and ." -ForegroundColor Green
                Move-VM -VM $_ -Destination $SrcHost -Datastore $SrcDS -DiskStorageFormat $DiskFormat | Out-Null
                
            }
            
            # If $ExitCodeInvokeCommand -eq 1, sdelete.exe wasn't found. Skip this VM.
            
            elseif ( $ExitCodeInvokeCommand -eq 1 ) {
                
                Write-Host "`n"
                Write-Host 'SDelete was not found. Skipping this VM' -ForegroundColor Red
                
            }
            
        }
    }
}

# Disconnect from vCenter Server
Write-Host "`n"
Write-Host "Disconnecting from vCenter Server $VIServer" -ForegroundColor Green
Disconnect-VIServer $VIServer -Force -Confirm:$false | Out-Null