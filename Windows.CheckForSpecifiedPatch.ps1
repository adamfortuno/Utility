$patch_history = @();

$servers = @('server1'
, 'server2'
)

$ErrorActionPreference = 'Stop'

foreach ($server in $servers) {
    try {
        Write-Host "Querying ${server}..."
        
        $history_item = New-Object -TypeName PSObject

        Add-Member -InputObject $history_item -MemberType NoteProperty -Name ServerName -Value $server

        $hot_fix = $(Get-Hotfix -HFID KB4040685 -ComputerName $server)
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Patched'
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Comment -Value $hot_fix.InstalledOn
    } catch [System.ArgumentException] {
        Write-Host "Hotfix not found on ${server}..."
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Unpatched'
    } catch {
        Write-Host "Unable to query ${server}."
        Add-Member -InputObject $history_item -MemberType NoteProperty -Name Status -Value 'Unable to Verify'
    } finally {
        $patch_history += $history_item
    }  
}