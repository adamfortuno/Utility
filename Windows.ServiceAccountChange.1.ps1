Set-StrictMode -Version 2

## Service status reference
## http://msdn.microsoft.com/en-us/library/aa393673(v=vs.85).aspx

## StartService return codes
## http://msdn.microsoft.com/en-us/library/aa393660(v=vs.85).aspx

## StopService return codes
## http://msdn.microsoft.com/en-us/library/aa393673(v=vs.85).aspx

$user_name = 'MyDomain\foo'
$password = '<foo-password>'
$service_name = 'SQLsafe Backup Service'
#$service_name = 'SQLcomplianceAgent$SQL16VWP'

$machines = @('tba')

foreach ($machine in $machines) {  
	Write-Host "Modifying service on ${machine}."
	
	## Pull back a service object
	$service = gwmi Win32_Service -ComputerName $machine -Filter "name='${service_name}'"

	## Change the service's credentials
	$result = $service.Change($null, $null, $null, $null, $null, $null, $user_name, $password, $null, $null, $null)
	
	## If the change was successful and the service is running, restart it.
	if ($result.ReturnValue -eq 0) {
		Write-Host '...credential change applied to service.'
		if ($service.State -eq 'Running') {
			Write-Host '...service is in the running state, attempting restart.'
			
			$result = $service.StopService()
			
			while ($service.State -ne 'Stopped') {
				$service = gwmi Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
				Start-Sleep -s 2
			}

			if ($result.ReturnValue -eq 0) {
				Write-Host '...service stopped successfully.'

				$result = $service.StartService()

				if ($result.ReturnValue -eq 0) {
					while ($service.State -ne 'Running') {
						$service = gwmi Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
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
						$service = gwmi Win32_Service -ComputerName $machine -Filter "name='${service_name}'"
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