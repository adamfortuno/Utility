<#
    .Synopsis
    The script reviews file locations for each user database served by the instance. If the 
    database's files aren't in the specified location, the database is attached, and the files
    are moved to the target location.

    .Description
    This script moves files for user databases (i.e., not msdb, master, model, or tempdb) on a
    specified instance to a specified path. The script accepts a path to a configuration file.
    The file specifies what intances to evaluate and preferred location for data and log files.
    The file's format is as follows:

    <instance_name>,<data_file_location>,<log_file_location>

    1. SQL Server Management Objects (SMO)
    2. Powershell 2.0
    3. Caller's context has rights to attach and detach databases
    4. caller's context has rights to modify contents of the source and target directories

    .Parameter PathToConfigurationFile
    The full or logical path to the configuration file.

    .Example
    .\run.ps1 .\instances.dev.csv
#>
Param ([Parameter(Position=1,Mandatory=$true)][string]$PathToConfigurationFile)

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

$instance_list = Import-Csv -Delimiter ',' -Path $PathToConfigurationFile -Header instance_name, path_data_file ,path_log_file

Foreach ($configuration in $instance_list) {
        Write-Host "Examining databases on $($configuration.instance_name)..."

        ## Ensure the target paths exists before doing anything
        if (!(Test-Path -LiteralPath $configuration.path_data_file)) {
                throw "The path for this instance's data files looks incorrect."
        }
        if (!(Test-Path -LiteralPath $configuration.path_log_file)) {
                throw "The path for this instance's transaction-log files looks incorrect."
        }

        $instance = New-Object "Microsoft.SqlServer.Management.Smo.Server" $configuration.instance_name
        $configuration.path_log_file = clean_path $configuration.path_log_file
        $configuration.path_data_file = clean_path $configuration.path_data_file
        $target_databases = @()
        
        ## Build a list of databases who's files aren't in the right place. The
        #  list of offending databases will be in $target_databases
        Foreach ($database in $($instance.Databases | Where-Object { $_.IsSystemObject -eq $false }) ) {
                $change_not_needed = $true
                
                ## Review the placement of transaction-log files
                Foreach ($file in $database.LogFiles) {
                        If ($change_not_needed) {
                            If ($(split-path -Path $file.FileName) -ne $configuration.path_log_file) {
                                    Write-Host "$($file.FileName) is not in $($configuration.path_log_file)"
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
                                                if ($(split-path -Path $file.FileName) -ne $configuration.path_data_file) {
                                                        Write-Host "$($file.FileName) is not in $($configuration.path_data_file)"
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
                $files = New-Object 'System.Collections.Specialized.StringCollection'
                $file_list = @()
                [string]$filename = ''
              
				## Build a list of transaction log files that need to be moved
                Foreach ($file in $database.LogFiles) {
                    $file_list_item = New-Object System.Object
                    
                    Add-Member -InputObject $file_list_item -type NoteProperty -name source -value $file.FileName
                    
                    $filename = ${configuration}.path_log_file
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
                            $filename = ${configuration}.path_data_file
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
}