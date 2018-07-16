$list_of_names = @("server1", "server2", "server3")
$translations = @{}

# Lets resolve each of these addresses
foreach ($name in $list_of_names) {
     Write-Host $name
     
     $Result = $Null
    
     $currentEAP = $ErrorActionPreference
     $ErrorActionPreference = "silentlycontinue"
    
     $result = [System.Net.Dns]::GetHostEntry($name)
     
     $ErrorActionPreference = $currentEAP
     
     If ($Result){
          $address = [string]$result.AddressList.IPAddressToString
     }
     
     $translations.Add($name, $address)
}
 
$translations