$Param($ServerName)

$directory = '~\Documents'
$path = "${directory}\$(get-date -uformat "%Y_%m_%d_%H_%M").csv"
Get-WMIObject win32_processor -ComputerName $ServerName `
	| Select-Object DeviceID, LoadPercentage `
	| Export-CSV -Path $path -NoTypeInformation