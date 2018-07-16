Set-StrictMode -Version 2

function clean_path ([string]$path) {
        [string]$clean_path = $path
        
        if ($clean_path[-1] -eq '\') {
                $clean_path = $clean_path.Remove($clean_path.Length - 1, 1)
        }
        
        return $clean_path
}

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Collections.Specialized") | Out-Null

$target_instance = 'server1'
$path_log_file = 'H:\LogFiles'
$path_data_file = 'L:\DataFiles'
$target_databases = @()

## Ensure the target paths exists before doing anything
if (!(Test-Path -LiteralPath $path_data_file)) {
	throw "The path for this instance's data files looks incorrect."
}
if (!(Test-Path -LiteralPath $path_log_file)) {
	throw "The path for this instance's transaction-log files looks incorrect."
}

$instance = New-Object "Microsoft.SqlServer.Management.Smo.Server" $target_instance

## Build a list of databases who's files aren't in the right place. The
#  list of offending databases will be in $target_databases
Foreach ($database in $($instance.Databases | Where-Object { $_.IsSystemObject -eq $false }) ) {
	$change_not_needed = $true

	## Review the placement of transaction-log files
	Foreach ($file in $database.LogFiles) {
		If ($change_not_needed) {
		    If ($(split-path -Path $file.FileName) -ne $path_log_file) {
			    Write-Host "$($file.FileName) is not in $($path_log_file)"
			    $target_databases += $database
			    $change_not_needed = $False
			    Break
		    }
		}
	}

	## Review the placement of data files
	if ($change_not_needed) {
		Foreach ($filegroup in $database.FileGroups) {
			Foreach ($file in $filegroup.Files) {
				if ($change_not_needed) {
					if ($(split-path -Path $file.FileName) -ne $path_data_file) {
						Write-Host "$($file.FileName) is not in $($path_data_file)"
						$target_databases += $database
						$change_not_needed = $false
						break
					}
				}
			}
		}
	}
}

# Detach the naughty databases
Foreach ($database in $target_databases) {
	$database_connection_count = $database.ActiveConnections
	If (Read-Host "${database} has ${database_connection_count} connections. Continue to move?" )

	$files = New-Object 'System.Collections.Specialized.StringCollection'
	$file_list = @()
	[string]$filename = ''

	## Build a list of transaction log files that need to be moved
	Foreach ($file in $database.LogFiles) {
	    $file_list_item = New-Object System.Object

	    Add-Member -InputObject $file_list_item -type NoteProperty -name source -value $file.FileName

	    $filename = $path_log_file
	    $filename += '\'
	    $filename += (Split-Path -Path $file.FileName -Leaf)

	    Add-Member -InputObject $file_list_item -type NoteProperty -name target -value $filename

	    $file_list += $file_list_item
	}

			## Build a list of data files that need to be moved
	Foreach ($filegroup in $database.FileGroups) {
		Foreach ($file in $filegroup.Files) {
		    $file_list_item = New-Object System.Object

		    Add-Member -InputObject $file_list_item -type NoteProperty -name source -value $file.FileName
		    $filename = $path_data_file
		    $filename += '\'
		    $filename += (Split-Path -Path $file.FileName -Leaf)
		    Add-Member -InputObject $file_list_item -type NoteProperty -name target -value $filename

		    $file_list += $file_list_item                            
		}
	}

			## Detach the offending database
	$instance.DetachDatabase($database.name, $false)

	## Move the specified data and transaction-log files to the specified location
	Foreach ($file_list_item in $file_list) {
	    Move-Item -LiteralPath $file_list_item.source -Destination $file_list_item.target -Force
	    $files.Add($file_list_item.target)
	}

	## Attach the offending database
	$instance.AttachDatabase($database.name, $files)
}