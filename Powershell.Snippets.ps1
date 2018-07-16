###############################################################################
# Powershell Snippets
###############################################################################

##Load the SMO assembly (old school way). Loads the latest library
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");

##Load the SMO assembly (version-2.0 and later way). If there are multiple versions of
##SMO installed, this will bomb. In that case, go with the next option.
Add-Type -AssemblyName "Microsoft.SqlServer.Smo"

##Load a specific version of SMO (in this case 14.0)
Add-Type -path "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\14.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"

<##############################################################################
NOTE: The GAC (C:\Windows\assembly\) has a directory for each library e.g.

C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\

That directory contains a directory for each version of the library (e.g., 11.0, 13.0, 14.0)

C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\12.0.0.0__89845dcd8080cc91
C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\14.0.0.0__89845dcd8080cc91\

Inside the version folder, is the assembly.
##############################################################################>

##Get the name and version from a given assembly
$assembly_path = "C:\Windows\assembly\GAC_MSIL\Microsoft.SqlServer.Smo\14.0.0.0__89845dcd8080cc91\Microsoft.SqlServer.Smo.dll"
$assembly = [Reflection.Assembly]::Loadfile($assembly_path)
$assembly.GetName()

##Time a given event with a .Net stopwatch object
$stop_watch = [Diagnostics.Stopwatch]::StartNew()
Start-Sleep 3
$stop_watch.Stop()
$stop_watch.Elapsed

##Create a Progress Bar
for ($count=1; $count -lt 100; $count++) {
  Write-Progress -Activity "Working..." -PercentComplete $a -CurrentOperation "$a% complete" -Status "Please wait."
  Start-Sleep 1
}
Write-Progress -Activity "Working..." -Completed -Status "All done."

##Verify a process is listening on a given port
(New-Object Net.Sockets.TcpClient).Connect("10.252.152.82", 5696)

# ...or...

Get-NetTCPConnection -RemoteAddress 10.146.121.174 -RemotePort 1433

##Get the IPv4 Addresses for a Set of Machines
Get-NetIPAddress -CimSession $servers -AddressFamily IPv4 | Select PSComputerName, IPAddress

##Get the Addresses for specific interfaces
Get-NetIPAddress -CimSession $servers -AddressFamily IPv4 `
| Select PSComputerName, IPAddress, InterfaceAlias `
| where { $_.InterfaceAlias -notmatch '.*-b' -and $_.InterfaceAlias -notmatch '.*Loopback.*' }

## Determine if a specific patch was installed on a set of servers
$patch_history = @();

$servers = @('DBADFS-AS-3P'
, 'DBADFS-CH2-3P'
, 'DBADFS-HO-3P'
, 'DBADFS-PO-3P')

$ErrorActionPreference = "Stop"

foreach ($server in $servers) {
    try {
        Write-Host "Querying ${server}..."
        
        $history_item = New-Object -TypeName PSObject

        Add-Member -InputObject $history_item -MemberType NoteProperty -Name ServerName -Value $server

        $hot_fix = $(Get-Hotfix -HFID KB4040685 -ComputerName $server)
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Patched'
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Comment -Value $hot_fix.InstalledOn
    } catch [System.ArgumentException] {
        Write-Host "Hotfix not found on ${server}..."
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Unpatched'
    } catch {
        Write-Host "Unable to query ${server}."
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Unable to Verify'
    } finally {
        $patch_history += $history_item
    }  
}

## Searching AD for a User
Get-ADDomain -Server apac.comcast.com
Get-ADUser -SearchBase "CN=Users,DC=apac,DC=comcast,DC=com" -Filter { Surname -like 'Gangadhar' }
Get-ADUser -Server apac.comcast.com -Filter { Surname -like 'Elangovan' } | Select Surname, GivenName, Name

##See what certificates are located in my folder in the local Windows Certificate Store
Import-Module PKI
Set-Location Cert:
ls .\\CurrentUser\My\39* | fl

##Disable a SQL Server login
$instance.Logins['sa'].Disable()
$instance.Logins['sa'].ChangePassword($([System.Web.Security.Membership]::GeneratePassword(128,0)));