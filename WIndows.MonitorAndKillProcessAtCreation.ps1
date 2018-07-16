<#
    .Synopsis
	Monitor Hunter

    .Description
	This script monitors a specified machine for a given
	process. If the process is found, it is terminated,
	and details of the process' creation are recorded in the
	log.

	.Parameter ComputerName
	The name of the computer being monitored.

	.Parameter ProcessName
	The name of the process being monitored for.

	.Parameter LogFilePath
	The full path to the monitor's log file.

	.Example
	.\monitor_process -ProcessName 'OpenWith.exe'

	Monitors for the creation of the 'OpenWith.exe' process. If
	the process is found, it's terminated and details about it's
	creation are recorded in the log.
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false,Position=1)][string]$ComputerName
  , [Parameter(Mandatory=$true,Position=2)][string]$ProcessName
  , [Parameter(Mandatory=$false,Position=3)][string]$LogFilePath
)

Set-StrictMode -Version 5.0

$current_context = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if ( $current_context.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false ) {
	throw 'Run this script as an administrator.'
}

## If a log file location wasn't specified, create one in the same
## directory as the script.
if ( $PSBoundParameters.ContainsKey('LogFilePath') -eq $false ) {
	$self_location = $MyInvocation.MyCommand.Path
	$self_directory = Split-Path -Path $self_location -Parent
	$log_file_name = 'monitor_process_log_{0}.txt' -f $(Get-Date -Format yyyyMMdd)
	$LogFilePath = Join-Path -path $self_directory -ChildPath $log_file_name
}

## Build the event subscription identifier
$target_machine = if ( $PSBoundParameters.ContainsKey('ComputerName') ) { $ComputerName } else { 'self' }
$subscription_identifier = "watch_for_process_${ProcessName}_on_${target_machine}".Replace('.', '_')

## Build the WMI query string
$query_process_start = "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName = '${ProcessName}'"

## Script block to execute when the event occurs
$event_response_process_launch = {
	$process_id_target = $event.SourceEventArgs.newevent.ProcessID
	$process_parent = $(Get-Process -ID $event.SourceEventArgs.newevent.ParentProcessID)
	
	$process_data = [PSCustomObject]@{
		ProcessID = $process_id_target
		ProcessName = $event.SourceEventArgs.newevent.ProcessName
		ProcessStartDate = $(Get-Date -Format 'G').ToString()
		ProcessCall = `
			$(Get-CimInstance -ClassName Win32_process -Filter "ProcessId = ${process_id_target}").CommandLine
		ParentProcessID = $event.SourceEventArgs.newevent.ParentProcessID
		ParentProcessName = $process_parent.ProcessName
		ParentProcessStartTime = $process_parent.StartTime.ToString()
	}
	
	Stop-Process $event.SourceEventArgs.newevent.processID -Force
	
	$process_data | ConvertTo-Json | Out-File -Append -FilePath $event.MessageData
}

## Register the event handler
Register-CimIndicationEvent -Query $query_process_start `
	-SourceIdentifier $subscription_identifier `
	-Action $event_response_process_launch `
	-MessageData $LogFilePath `
	-ComputerName $ComputerName `
	-ErrorAction 'Stop'

## Return the event handler to the requester
Get-EventSubscriber -SourceIdentifier $subscription_identifier