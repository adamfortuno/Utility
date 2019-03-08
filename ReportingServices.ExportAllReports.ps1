<#
    .Synopsis
    Export All Reporting Services Reports to Disk
    
    .Description
    This script exports all SQL Server Reporting Services reports
    to the current folder.
    
    .Parameter ReportServerURI
    The URI of the report server's web service endpoint. The endpoints
    are available to manage the report server via web service
    call.

    .Parameter ExportPath
    The path to where the export bundle will be created.
    
    .link
    https://docs.microsoft.com/en-us/sql/reporting-services/report-server-web-service/methods/report-server-web-service-endpoints

    For a full discussion of report server web service endpoints see the MSDN article titled Report Server Web Service Endpoints.

    .Example
    .\get_reports.ps1 `
        -ReportServerURI 'http://localhost:8080/ReportServer_SS2K12/ReportService2005.asmx'

    .Example
    .\get_reports.ps1 `
        -ReportServerURI 'http://localhost:8080/ReportServer_SS2K12/ReportService2005.asmx' `
        -ExportPath "C:\Users\adam.fortuno\Documents\"
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true, Position=1)]
    [string]$ReportServerURI
  , [Parameter(Mandatory=$false, Position=2)]
    [string]$ExportPath
)

Set-StrictMode -Version 5

Add-Type -AssemblyName 'System.IO'

$self_path = $script:MyInvocation.MyCommand.Path    
$self_directory = Split-Path -Path $self_path -Parent

if ( [string]::IsNullOrEmpty($ExportPath) ) { 
    $export_directory_path = $self_directory
} else {
    $export_directory_path = $ExportPath
}

$export_directory_name = `
    "{0}_{1}" -f $([System.Uri]$ReportServerURI).DnsSafeHost, $(Get-Date -Format "yyyyMMdd_hhmmss")
$export_directory = Join-Path -Path $export_directory_path -ChildPath $export_directory_name

## Retrieve the reporting objects from the specified instance
try {
    $source_reportserver = New-WebServiceProxy `
        -Uri $ReportServerURI `
        -Namespace 'SSRS.ReportingService2005' `
        -UseDefaultCredential

    $source_reportserver_objects = $source_reportserver.ListChildren("/", $true) `
        | Select-Object Type, Path, ID, Name `
        | Where-Object {$_.type -eq "Report"}

    ## Create the export folder
    Write-Output "Creating export directory..."
    New-Item -Path $export_directory -Type Directory -Force | Out-Null

    foreach($reportserver_object in $source_reportserver_objects) {
        $report_name = "{0}.{1}" -f $(Split-Path $reportserver_object.Path -Leaf), "rdl"
        $report_path = Split-Path $reportserver_object.Path
        $export_report_directory = $export_directory + $report_path
        $export_report_fullname = Join-Path -Path $export_report_directory -ChildPath $report_name
        
        Write-Output "Processing ${report_name}..."

        ## Create the report's directory if it doesn't exist
        Write-Output "...identifying export folder."
        If( $(Test-Path $export_report_directory) -eq $False ) {
            New-Item -Path $export_report_directory -Type Directory -Force | Out-Null
        }
    
        Write-Output "...exporting report."
        $export_report_rdl = New-Object 'System.Xml.XmlDocument'
        [byte[]] $export_report_raw = $null
        $export_report_raw = $source_reportserver.GetReportDefinition($reportserver_object.Path)

        [System.IO.MemoryStream]$export_report_stream = `
            New-Object 'System.IO.MemoryStream' -ArgumentList (@(,$export_report_raw))
        
        $export_report_rdl.Load($export_report_stream)
        $export_report_rdl.Save($export_report_fullname)
    }
} catch {
    throw $error[0]
}