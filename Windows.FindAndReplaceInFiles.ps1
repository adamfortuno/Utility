$changes = @{'PHL-ENT-DBN01' = 'QA1-FRWY-SQL01';
'PHL-ENT-DBN02' = 'QA1-FRWY-SQL01';
'UA1-ENT-DBG02' = 'QA1-FRWY-SQL01';
'arctic\\sql_server_administration' = 'freedompay1\sql_data_administration';
'arctic\\svc-e01-rep-logr' = 'freedompay1\SVC-QAT01-REP-LOGR';
'tHKBW4n6FGOWPmLKJNLX' = '@0w7aWq2XsGyuKlDs#My';
'arctic\\svc-e01-rep-snap' = 'freedompay1\SVC-QAT01-REP-SNAP';
'018wxMUMTOcGnspa9gBJ' = '9Wt6P9LE5B3DD04KiyMX';
'arctic\\svc-e01-rep-dist' = 'freedompay1\SVC-QAT01-REP-DIST';
'e38UJCUXLQl0Psy3bHS4' = 'J$57cx_NW=nJynp%^dE$'}
	
$target_directory = '\\NAS\shared\data_services\shared_files\environment_quality_assurance\environment_creation\replication_setup'
$files = ls $target_directory

foreach ($file in $files) {
	Write-Host "Updating $($file.name)..." -ForegroundColor Red
	
	$file_contents = Get-Content $file.FullName
	
	foreach ($change in $changes.keys) {
		$find_string = $change
		$replace_string = $changes[$change]

		Write-Host "...changing '${find_string}' to '${replace_string}'" -ForegroundColor Red
		
		$file_contents = $file_contents | Foreach-Object {$_ -replace $find_string, $replace_string} 
	}
	
	$file_contents | Set-Content $file.FullName
}


Error messages:
INSERT failed because the following SET options have incorrect settings: 'ANSI_PADDING'. Verify that SET options are correct for use with indexed views and/or indexes on computed columns and/or filtered indexes and/or query notifications and/or XML data type methods and/or spatial index operations. (Source: MSSQLServer, Error number: 1934)
Get help: http://help/1934
INSERT failed because the following SET options have incorrect settings: 'ANSI_PADDING'. Verify that SET options are correct for use with indexed views and/or indexes on computed columns and/or filtered indexes and/or query notifications and/or XML data type methods and/or spatial index operations. (Source: MSSQLServer, Error number: 1934)
Get help: http://help/1934