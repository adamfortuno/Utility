<#
.Synopsis
 Change Service Account Credentials

.Description
 This script changes the crednetials of a specified service account
 to those provided. The script can target an installation of a 
 service on a single machine or multiple machines. For example, you 
 can change the password for a SQL Server instance 

 The person executing this script should be a member of any target
 machine's local Administration group.

.Parameter UserName
 The username of the crential you will be assigning to the service.

.Parameter Password
 The password of the crential you will be assigning to the service

.Parameter ServiceName
 The name of the service who's account you would like to update.

.Parameter ComputerName
 The name of the computer hosting the service you would like to 
 update.

.Example
 ./service_account_change.ps1 -UserName svc-dev-sql05-mongod -Password slipperyFoxFiveg9! -ServiceName MongoDB -ComputerName dev-sql05
 
.References
 Service status reference
 http://msdn.microsoft.com/en-us/library/aa393673(v=vs.85).aspx

 StartService return codes
 http://msdn.microsoft.com/en-us/library/aa393660(v=vs.85).aspx

 StopService return codes
 http://msdn.microsoft.com/en-us/library/aa393673(v=vs.85).aspx
#>

Param (
    [Parameter(Mandatory=$true, Position=1)][string]$UserName
  , [Parameter(Mandatory=$true, Position=2)][string]$Password
  , [Parameter(Mandatory=$true, Position=3)][string]$ServiceName
  , [Parameter(Mandatory=$true, Position=3)][string[]]$ComputerName
) 

Set-StrictMode -Version 2.0

$user_name = $UserName
$password = $Password
$service_name = $ServiceName
$machines = $ComputerName

foreach ($machine in $machines) {  
              Write-Host "Modifying service on ${machine}."
              
              ##Pull back a service object
              $service = Get-WmiObject Win32_Service -ComputerName $machine -Filter "name='${service_name}'"

              ##Change the service's credentials
              $result = $service.Change($null, $null, $null, $null, $null, $null, $user_name, $password, $null, $null, $null)
              
              ##If the change was successful and the service is running, restart it.
              if ($result.ReturnValue -eq 0) {
                           Write-Host '...credential change applied to service.'
                           
                           if ($service.State -eq 'Running') {
                                         Write-Host '...service is in the running state, attempting restart.'
                                         
                                         $result = $service.StopService()
                                         
                                         while ($service.State -ne 'Stopped') {
                                                       $service = Get-WmiObject Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
                                                       Start-Sleep -s 2
                                         }

                                         if ($result.ReturnValue -eq 0) {
                                                       Write-Host '...service stopped successfully.'

                                                       $result = $service.StartService()

                                                       if ($result.ReturnValue -eq 0) {
                                                                    while ($service.State -ne 'Running') {
                                                                                  $service = Get-WmiObject Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
                                                                                  Start-Sleep -s 2
                                                                    }
                                                                    
                                                                    Write-Host "...service started successfully."
                                                       } else {
                                                                    Write-Host "...service failed to start successfully."
                                                                    Write-Host "...$($result.ReturnValue) was returned from start request."
                                                       }
                                         } else {
                                                       Write-Host '...service failed to stop successfully.'
                                                       Write-Host "...$($result.ReturnValue) was returned from stop request."
                                         }
                           } else {
                                         $is = Read-Host "The service is in a stopped state. Type 'Y' if you would like to start this service."
                                         
                                         if ($is.ToUpper() -eq 'Y') {
                                                       $result = $service.StartService()

                                                       if ($result.ReturnValue -eq 0) {
                                                                    while ($service.State -ne 'Running') {
                                                                                  $service = Get-WmiObject Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
                                                                                  Start-Sleep -s 2
                                                                    }
                                                                    
                                                                    Write-Host "...service started successfully."
                                                       } else {
                                                                    Write-Host "...service failed to start successfully."
                                                                    Write-Host "...$($result.ReturnValue) was returned from start request."
                                                       }
                                         }
                           }
              } else {
                           Write-Host '...attempt to apply credential change failed.'
                           Write-Host "...$($result.ReturnValue) was returned from credential change request."
              }
}