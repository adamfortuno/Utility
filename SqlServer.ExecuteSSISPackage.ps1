##Load the SMO and IntegrationServices assemblies
[Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.IntegrationServices')
[Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')

##You'll establish a connection to the database utility server (e.g., ua1-ent-dbs01) then use that to
##access the SSIS service on that machine
$sql_connection_string = 'Data Source=(local)\ss2k14;Initial Catalog=master;Integrated Security=SSPI;'
$sql_connection = New-Object 'System.Data.SqlClient.SqlConnection' $sql_connection_string
$ssis = New-Object "Microsoft.SqlServer.Management.IntegrationServices.IntegrationServices" $sql_connection

##For my example, we'll execute the cnh_export_reward_card_summary package
$catalog = $ssis.catalogs['ssisdb']
$package = $catalog.Folders['enterprise'].Projects['cnh'].Packages['cnh_export_reward_card_summary.dtsx']

##Passing in a bunch of parameters
$parameters = New-Object 'System.Collections.ObjectModel.Collection[Microsoft.SqlServer.Management.IntegrationServices.PackageInfo+ExecutionValueParameterSet]'

$parameter = New-Object 'Microsoft.SqlServer.Management.IntegrationServices.PackageInfo+ExecutionValueParameterSet';
$parameter.ObjectType = 30;
$parameter.ParameterName = "connection_string_source";
$parameter.ParameterValue = 'Data Source=database2;Initial Catalog=fp_test;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;';
$parameters.Add($parameter);

$parameter = New-Object 'Microsoft.SqlServer.Management.IntegrationServices.PackageInfo+ExecutionValueParameterSet';
$parameter.ObjectType = 30;
$parameter.ParameterName = "path_file_export";
$parameter.ParameterValue = 'C:\temp\ftp_cnh';
$parameters.Add($parameter);

$parameter = New-Object 'Microsoft.SqlServer.Management.IntegrationServices.PackageInfo+ExecutionValueParameterSet';
$parameter.ObjectType = 30;
$parameter.ParameterName = "path_file_template";
$parameter.ParameterValue = 'C:\temp\working\cnh\';
$parameters.Add($parameter);

##I execute the package (passing in the parameters collection) and save the results
$execution = $package.Execute($False, $Null, $parameters)
$results = $catalog.Executions[$execution];

##For giggles, I'm displaying the return messages (120's are errors)
$results.Messages | Sort messagetime -Descending | Select MessageType, Message