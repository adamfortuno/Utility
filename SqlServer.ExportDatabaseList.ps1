Set-StrictMode -Version 2

<#
Server.txt should have content that appears like...

server1
server2
server3
#>

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

$instances = gc .\instances.txt
$databases = @()

foreach ($instance_name in $instances) {
    $instance = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $instance_name
    
    $databases += $instance.Databases | Where { $_.IsSystemObject -eq $False } | Select @{Expression={$instance};Label='Instance'}, Name, Size, Owner, CreateDate
    
    
}

$databases | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation