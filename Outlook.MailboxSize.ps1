$outlook = New-Object -com Outlook.Application
$mailbox = $outlook.getnamespace('mapi')
$archiveBin = $mailbox.Session.Stores | Where-Object {$_.DisplayName -eq 'Archive Folders'}
$rootFolder = $archiveBin.getRootFolder()
$targetFolder = $rootFolder.Folders | Where-Object {$_.Name -eq 'temp'}
$targetFolder.Items `
| Select-Object Size, CreationTime `
| export-csv message_sizes.csv -UseCulture -NoTypeInformation