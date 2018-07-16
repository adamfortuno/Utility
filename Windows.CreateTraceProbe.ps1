#requires -version 2.0

Param (
    [Parameter(Mandatory=$True,Position=1)][string]$HostName
  , [Parameter(Mandatory=$True,Position=2)][string]$PathToExecutable
  , [Parameter(Mandatory=$True,Position=3)][string]$PathForOutput
)

Set-StrictMode -Version 2

##Verify that the target machine is accessible
Write-Verbose -Message "$(Get-Date -Format G): Verifying that ${HostName} is accessible."

If ((Test-Connection -ComputerName $HostName -Count 3 -Quiet) -eq $False) {
    Throw 'The target machine, ${HostName}, is inaccessible.'
}

##Verify that the output path is accessible
Write-Verbose -Message "$(Get-Date -Format G): Verifying that ${PathForOutput} is accessible."

If ((Test-Path -LiteralPath $PathForOutput -PathType Container) -eq $False) {
    Throw 'The output path, ${PathForOutput}, could not be found.'
}
$wmi_namespace = 'root\cimv2'
$wmi_idfr_process_trace = 'trace_probe_' + [guid]::NewGuid()

##Starting the probe on the remote machine
$process_probe = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList $PathToExecutable -ComputerName $HostName -Namespace $wmi_namespace

Write-Verbose -Message "$(get-date -Format G): Process $($process_probe.ProcessID) was initiated on ${HostName}."

Try {
    ##Verifying the probe process is running.
    Get-Process -Id $process_probe.ProcessID -ComputerName $HostName -ErrorAction Stop | Out-Null

    ##Registering the probe process trace event.
    Write-Verbose -Message "$(get-date -Format G): Registering WMI process trace event on ${HostName}."
    
    $wmi_qry_process_trace = "SELECT * FROM Win32_ProcessStopTrace WHERE ProcessID=$($process_probe.ProcessID)"
    Write-Verbose -Message $wmi_qry_process_trace
    Register-WmiEvent -Query $wmi_qry_process_trace -SourceIdentifier $wmi_idfr_process_trace -ComputerName $HostName
    
    ##Waiting for the trace event to fire.
    Write-Verbose -Message "$(get-date -Format G): Creating wait on process trace event ${wmi_idfr_process_trace}."
    
    $event = Wait-Event -SourceIdentifier $wmi_idfr_process_trace
    
    Write-Verbose -Message "$(get-date -Format G): Event registered."

    ##Copying the probe's files
    #TBA

} Catch [System.Management.Automation.ActionPreferenceStopException] {
    Throw "The process could not be found.`n`n$error[0]"
} Catch {
    Throw "An unexpected error occured.`n`n$error[0]"
}