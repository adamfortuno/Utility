Param ([Parameter(Mandatory=$True,Position=1)][string]$LoginNamePattern)
Set-StrictMode -Version 2

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

$found = @()

Foreach ($instance_record in $(gc ..\configurations\instances.txt)) {

	## Skip comments and blank lines in the list.
	If (-Not $instance_record.StartsWith('#') -and $instance_record.Trim() -ne '') {
		
		## Parse out the instance's name from the record (position 0)
		$instance_name = $instance_record.Split("`t")[0]
		
		Write-Host "Checking ${instance_name}..."
		
		try {
		
			## Connect to the instance
			$instance = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $instance_name
			$instance.ConnectionContext.ConnectTimeout = 10
			$instance.ConnectionContext.Connect()

			## Search the instance's logins for one that matches the supplied pattern
			Foreach ($login in $instance.Logins) {
				If ($login.Name -ilike $LoginNamePattern) {
					## Add the login and it's instance to our list of matches
					$found += $login | Select @{Name='Instance';Expression={$_.Parent.Name}}, Name
				}
			}
		} catch {
			Write-Host "Unable to connect to ${instance_name}." -ForegroundColor Red
		}
	}
}

## If there are any matches, pass them to the next process; otherwise, output nothing found.
if ($found) {
	$found
} else {
	Write-Host "No logins found matching the name-pattern '${LoginNamePattern}'." -ForegroundColor Yellow
}