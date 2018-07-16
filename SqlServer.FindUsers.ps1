Param ([Parameter(Mandatory=$True,Position=1)][string]$UserNamePattern)
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

			## Search each database hosted by the instance for a user that matches the name pattern
			Foreach ($database in $instance.Databases) {
				Foreach ($user in $database.Users) {
					If ($user.Name -ilike $UserNamePattern) {
						## Add the user and it's database and instance to our list of matches
						$found += $user | Select @{Name='Instance';Expression={$instance}}, @{Name='Database';Expression={$_.Parent.Name}}, Name
					}
				}
			}
		} catch {
			Write-Host "Unable to connect to ${instance_name}." -ForegroundColor Red
		}
	}
}

## If there are any matches, pass them to the next process; otherwise, output nothing found.
if ($found) {
	$found | Format-Table -AutoSize -Wrap
} else {
	Write-Host "No users found matching the name-pattern '${UserNamePattern}'." -ForegroundColor Yellow
}