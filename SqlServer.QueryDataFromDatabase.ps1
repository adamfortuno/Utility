## Define the variables.
$server_instance = "tsdv-af-l2\aslan"
$database = "DBTools"
$connection_string = "Provider=sqloledb;Data Source=${server_instance};Initial Catalog=${database};Integrated Security=SSPI;"

$db_connection = New-Object System.Data.OleDb.OleDbConnection $connection_string
$db_connection.Open()

$sql_statement_text = "select ExecutionState, count(*) from ServerEventHistory.[Job] where DateRecorded = convert(date, getdate()-20) group by ExecutionState;"
$sql_command = New-Object System.Data.OleDb.OleDbCommand $sql_statement_text, $db_connection
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter $sql_command
$result_set = New-Object System.Data.DataSet
$adapter.Fill($result_set)
$result_set.Tables | Select-Object -Expand Rows

$sql_statement_text = "select top 2 * from ServerEventHistory.[Role]"
$sql_command = New-Object System.Data.OleDb.OleDbCommand $sql_statement_text, $db_connection
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter $sql_command
$result_set = New-Object System.Data.DataSet
$adapter.Fill($result_set)
$result_set.Tables | Select-Object -Expand Rows

$result_set.Dispose()
$adapter.Dispose()
$db_connection.Close()