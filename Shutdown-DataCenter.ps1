<#
        .SYNOPSIS
        Es sind keine Parameter notwendig.

        .DESCRIPTION
        Das Skript migriert mittels PowerCLI alle VMs ins andere Rechenzentrum. Physikalische Server werden anschließend heruntergefahren.

        History  
        v0.1: Under development
     
        .EXAMPLE
        Shutdown-DataCenter
    
        .NOTES
        Author: Patrick Terlisten, p.terlisten@mlnetwork.de
    
        This script is provided 'AS IS' with no warranty expressed or implied. Run at your own risk.

        This work is licensed under a Creative Commons Attribution NonCommercial ShareAlike 4.0
        International License (https://creativecommons.org/licenses/by-nc-sa/4.0/).
    
        .LINK
        http://www.mlnetwork.de
#>

#Requires -Version 3.0
#Requires -Module VMware.VimAutomation.Core

### Circuit breaker
Write-Host `n
Write-Host -ForegroundColor Red "Die Skriptverarbeitung wurde abgebrochen. Das Skript ist momentan betriebsfrei geschaltet "
Write-Host `n

### Damit das Skript funktioniert, muss die Exit-Zeile auskommentiert werden.
exit

### Wenn ein Fehler gemeldet wird, dann soll die Skriptverarbeitung fortgesetzt werden.
$ErrorActionpreference = "continue"

### Funktionen, die im Skript verwendet werden.

function Shutdown-ESXHost
{
Param(
  [string]$ESXHost
  )

  ### Den ESXi Host in den Wartungsmodus versetzen und herunterfahren
  
  try
  {
    Write-Host -ForegroundColor Red "Versetze ESXi Host $ESXHost in den Wartungsmodus"
    Set-VMhost -VMhost $ESXHost -State Maintenance -Confirm:$false
    Write-Host -ForegroundColor Red "ESXi Host $ESXHost wurde in den Wartungsmodus versetzt"
    Write-Host -ForegroundColor Red "ESXi Host $ESXHost wird heruntergefahren"
    Stop-VMHost -VMHOST $ESXHost -confirm:$false
  }
  catch
  {
    Write-Host -ForegroundColor Red "Bei ESXi Host $ESXHost ist ein Fehler aufgetreten!"
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
  }
}

function Shutdown-HWServer
{
Param(
  [string]$HWHost
  )

  ### Den Server herunterfahren
  
  try
  {
    Write-Host -ForegroundColor Red "Server $HWHost wird heruntergefahren"
    Stop-computer -computerName $HWHost -force
  }
  catch
  {
    Write-Host -ForegroundColor Red "Bei Server $HWHost ist ein Fehler aufgetreten!"
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
  }
}

function Shutdown-HWServerAndWait
{
Param(
  [string]$HWHost
  )

  ### Den Server herunterfahren und warten
  
  try
  {
    Write-Host -ForegroundColor Red "Server $HWHost wird heruntergefahren"
    Stop-Computer -computerName $HWHost -force
    Write-Host -ForegroundColor Red "Fortführung des Skriptes in 5 Minuten"
    Start-Sleep 300
  }
  catch
  {
    Write-Host -ForegroundColor Red "Bei Server $HWHost ist ein Fehler aufgetreten!"
    "Error was $_"
    $line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
  }
}


### Grundlegenden Variablen

$ClusterName = DEZ2
$VIServer = 192.168.69.18
$CredFile = "C:\USV\Scripts\secure1.txt"
$Username = "Administrator@DEZ2"

### Stelle Verbindung zum vCenter her.
$Password = (Get-Content $CredFile | ConvertTo-SecureString)
New-Object System.Management.Automation.PSCredential ($Username, $Password)

Connect-VIServer $VIServer | Out-Null

### Prüfe HA Admission Control und deaktiviere Admission Control, sofern aktiviert.
if ((Get-Cluster $Clustername).HAAdmissionControlEnabled -eq $true)
{
  Write-Host -ForegroundColor Red "Deaktiviere HA Admission Control"
  Set-Cluster -Cluster $ClusterName -HAAdmissionControlEnabled:$true -confirm:$false
}


### Prüfe DRS und Automatisierungsmodus.
if ((Get-Cluster $Clustername).DrsEnabled -eq $False)
{
  Write-Host -ForegroundColor Red "DRS ist deaktiviert. Aktiviere DRS und setze Automationslevel auf vollautomatisiert."
  Set-Cluster -Cluster $ClusterName -DrsEnabled $true -DrsAutomationLevel FullyAutomated -Confirm:$false
}

elseif ((Get-Cluster $Clustername).DrsAutomationLevel -ne "FullyAutomated")
{ 
  Write-Host -ForegroundColor Red "DRS ist aktiviert. Setze Automationslevel auf vollautomatisiert."
  Set-Cluster -Cluster $ClusterName -DrsAutomationLevel FullyAutomated -Confirm:$false
}

### Erstelle Variable die alle ESXi Hosts im RZ-A beinhaltet
$ESXHostsRZA = Get-VMHost -Name rza*

### Evakuiere ESXi Hosts im RZ-A und fahre sie anschließend herunter

foreach ($ESXHost in $ESXHostsRZA)
					{
	 				Shutdown-ESXHost $ESXHost
					}

### Trenne die Verbindung zum vCenter
Disconnect-VIServer $VIServer -Force -Confirm:$false | Out-Null

### Variable die alle physikalischen Server im RZ-A enthält, die parallel heruntergefahren werden sollen

$HWHosts = @(
"rza-ms-scom-2.diakonie-michaelshoven.ad"
)

### Fahre physikalische Server herunter

foreach ($HWHost in $HWHosts) {Shutdown-HWServer $HWHost}

### Variable die alle physikalischen Server im RZ-A enthält, die nacheinander heruntergefahren werden sollen

$HWHostsAndWait = @(
"rza-ms-ssv-2.diakonie-michaelshoven.ad"
)

### Fahre physikalische Server herunter

foreach ($HWHostAndWait in $HWHostsAndWait) {Shutdown-HWServerAndWait $HWHostAndWait}


### Beende Skript
Write-Host -ForegroundColor Red "Fertg!"