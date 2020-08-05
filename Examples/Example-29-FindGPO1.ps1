﻿Import-Module "$PSScriptRoot\..\GPoZaurr.psd1" -Force

$Output = Invoke-GPOZaurr -GPOPath 'C:\Support\GitHub\GpoZaurr\Ignore\GPOExportEvotec1'
$Output | Format-Table
$Output.Reports.RegistrySettings | Format-Table *
$Output.Reports.InternetExplorerZones | Format-Table *

# Report to Excel of translated reports
foreach ($Key in $Output.Reports.Keys) {
    $Output.Reports[$Key] | ConvertTo-Excel -FilePath $Env:USERPROFILE\Desktop\GPOAnalysis.xlsx -ExcelWorkSheetName $Key -AutoFilter -AutoFit -FreezeTopRowFirstColumn
}

# Report to HTML of translated reports
New-HTML {
    foreach ($Key in $Output.Reports.Keys) {
        New-HTMLTab -Name $Key {
            New-HTMLTable -DataTable $Output.Reports[$Key] -Filtering
        }
    }
} -FilePath $Env:USERPROFILE\Desktop\GPOAnalysis.html -ShowHTML -Online