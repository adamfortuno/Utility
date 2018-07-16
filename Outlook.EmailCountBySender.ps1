<#
.Synopsis
 Get Numer of E-Mails by Sender

.DESCRIPTION
 This script returns a list of senders and the number of emails
 sent by that sender.

.EXAMPLE
 ./outlook_miner.ps1
#>
Set-StrictMode -Version 4.0

Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook"

$outlook = New-Object -ComObject Outlook.Application
$outlook_user = $outlook.GetNamespace("MAPI")
$inbox = $outlook_user.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)

$occurrences = @{}

##Record the number of e-mails with a given sender
foreach ($note in $inbox.items) {
    $occurrences[$note.SenderEmailAddress]++
}

##Return the list of senders by number of e-mails received
$occurrences.GetEnumerator() | Sort -Property Value -Descending | Format-Table -AutoSize