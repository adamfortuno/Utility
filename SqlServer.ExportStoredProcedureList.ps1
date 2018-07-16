[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null

$row_pointer = 2
$workbook_location = '$env:temp'
$instance_name = 'username'
$database_name = 'passwords'

"Pulling matching procedures from $database_name on ${instance_name}."

#Get all procedures that look like sp_*l_read
$server_instance = New-Object "Microsoft.SqlServer.Management.Smo.Server" $instance_name
$procs = $server_instance.Databases[$database_name].StoredProcedures `
       | Where-Object {$_.Name -like 'sp*l_read'} `
       | Sort Owner, Name `
       | Select Owner, Name, TextBody

"$($procs.Count) procedures found. Opening Microsoft Excel."

#Fire-up Excel and create a new workbook and worksheet
$program_excel = New-Object -comobject Excel.Application
$workbook = $program_excel.Workbooks.Add()
$active_worksheet = $workbook.Worksheets.Item(1)
$active_worksheet.Name = 'sp_xxxl_read Procedures'

"Microsoft Excel opened and workbook created. Copying data to workbook."

#Copy the procedure schema name, name, and body to the new Excel worksheet
$active_worksheet.Cells.Item(1,1) = 'Routine Name'
$active_worksheet.Cells.Item(1,2) = 'Routine DDL'
$active_worksheet.Cells.Item(1,3) = 'WHERE Predicate'
$active_worksheet.Cells.Item(1,4) = 'Order-By Clause'

foreach ($proc IN $procs) {
	$active_worksheet.Cells.Item($row_pointer,1) = '[' + $proc.Owner + '].[' + $proc.Name + ']'
	$active_worksheet.Cells.Item($row_pointer,2) = $proc.TextBody.Trim().ToUpper()

	$row_pointer++
}

$active_worksheet.Cells.RowHeight = 15

"Data copy complete. Saving workbook."

#Save the workbook and close Excel
$workbook.SaveAs($workbook_location)
$program_excel.Quit()

"Job complete. Workbook maybe found at ${workbook_location}."