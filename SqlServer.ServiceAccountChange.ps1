#

    This script will change the startup account of the specified SQL Service account on

    the machine you specify.  This script requires to be run in an elevated PowerShell session

    For Details on how to elevate your shell go to: http://bit.ly/anogNt

   

    This script can be run to just tell you about the SQL services that you have running

    on a given machine by highlighting until you get down to the first $ChangeService

   

    Make sure to change: "MyServerName", "MSSQLSERVER"(if that's not the one you want)

    , "DomainName\UserName", "YourPassword"

   

    This script may not work against a SQL Server that is not running PowerShell

 

    (c) Aaron Nelson

 

Warning:  I have not tested this with SSRS yet. 

#>

 

#Load the SqlWmiManagement assembly off of the DLL

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement") | out-null

$SMOWmiserver = New-Object ('Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer') "WIN7NetBook" #Suck in the server you want

 

#These just act as some queries about the SQL Services on the machine you specified.

$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-Table

#Same information just pivot the data

$SMOWmiserver.Services | select name, type, ServiceAccount, DisplayName, Properties, StartMode, StartupParameters | Format-List

 

#Specify the "Name" (from the query above) of the one service whose Service Account you want to change.

$ChangeService=$SMOWmiserver.Services | where {$_.name -eq "MSSQLSERVER"} #Make sure this is what you want changed!

#Check which service you have loaded first

$ChangeService

 

$UName="DomainName\UserName"

$PWord="YourPassword"

 

$ChangeService.SetServiceAccount($UName, $PWord)

#Now take a look at it afterwards

$ChangeService

 

#To soo what else you could do to that service run this:  $ChangeService | gm