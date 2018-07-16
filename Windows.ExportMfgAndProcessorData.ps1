<#
Script looks for a file named "machines.txt". The file should contain a list of servers such as...

ServerName1
ServerName2
#>

$processors = @()
$manufacturers = @()
$failures = @()

Write-Host 'Reading machine list...'
$machines = gc .\machines.txt

Write-Host "$($machines.Length) machines identified..."

Write-Host 'Retrieving information...'
Foreach ($machine in $machines) {
	try {
		Write-Host "Retrieving maufacturer information from ${machine}..."
		$manufacturers += gwmi -Class Win32_ComputerSystem -ComputerName $machine | Select Name, Model

		Write-Host "Retrieving processor information from ${machine}..."
		$processor = gwmi -Class win32_processor -ComputerName $machine | Select __SERVER, AddressWidth, numberOfCores, NumberOfLogicalProcessors
		$processors += $processor[0] | Select __SERVER, @{Name='processorCount';Expression={$processor.Count}}, AddressWidth, numberOfCores, NumberOfLogicalProcessors
	} catch {
		$failures += $machine
	}
}

$processors | ConvertTo-Csv -NoTypeInformation -Delimiter ',' > '.\processors.csv'
$manufacturers | ConvertTo-Csv -NoTypeInformation -Delimiter ',' > '.\manufacturers.csv'
$failures | ConvertTo-Csv -NoTypeInformation -Delimiter ',' > '.\failures.csv'