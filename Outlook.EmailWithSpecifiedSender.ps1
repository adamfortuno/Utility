Add-Type -AssemblyName 'Microsoft.Office.Interop.Outlook'

$ol = New-Object -ComObject 'Outlook.Application'
$ol.GetNameSpace('MAPI')
$ns = $ol.GetNameSpace('MAPI')
$fldr = $ns.GetDefaultFolder([Microsoft.Office.Interop.Outlook.olDefaultFolders]::olFolderInBox)
$fldr.Parent.Folders['database_management'].Folders['alerts_general'].Items | select subject


ReplyRecipientNames
$fldr.Parent.Folders['database_management'].Folders['alerts_general'].Items | where { $_.ReceivedTime -gt '2013-05-29T00:00:00.000' }
