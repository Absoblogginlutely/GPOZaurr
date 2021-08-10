﻿$GPOZaurrOrganizationalUnit = [ordered] @{
    Name           = 'Group Policy Organizational Units'
    Enabled        = $true
    ActionRequired = $null
    Data           = $null
    Execute        = {
        Get-GPOZaurrOrganizationalUnit -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    }
    Processing     = {
        # Create Per Domain Variables
        $Script:Reporting['GPOOrganizationalUnit']['Variables']['RequiresDiffFixPerDomain'] = @{}
        $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'] = @{}
        foreach ($OU in $Script:Reporting['GPOOrganizationalUnit']['Data']) {
            $Script:Reporting['GPOOrganizationalUnit']['Variables']['TotalOU']++
            # Create Per Domain Variables
            if (-not $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$OU.DomainName]) {
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$OU.DomainName] = 0
            }

            if ($OU.Status -contains 'Unlink GPO' -and $OU.Status -contains 'Delete OU') {
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPODeleteOU']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFix']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$OU.DomainName]++
            } elseif ($OU.Status -contains 'Unlink GPO') {
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPO']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFix']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$OU.DomainName]++
            } elseif ($OU.Status -contains 'Delete OU') {
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['DeleteOU']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFix']++
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$OU.DomainName]++
            } else {
                $Script:Reporting['GPOOrganizationalUnit']['Variables']['Legitimate']++

            }
        }
        if ($Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFix'] -gt 0) {
            $Script:Reporting['GPOOrganizationalUnit']['ActionRequired'] = $true
        } else {
            $Script:Reporting['GPOOrganizationalUnit']['ActionRequired'] = $false
        }
    }
    Variables      = @{
        TotalOU           = 0
        UnlinkGPO         = 0
        UnlinkGPODeleteOU = 0
        DeleteOU          = 0
        Legitimate        = 0
        WillFix           = 0
        WillFixPerDomain  = $null
    }
    Overview       = {

    }
    Summary        = {
        New-HTMLText -FontSize 10pt -Text @(
            "In most Active Directories there are a lot of Organizational Units that have different use cases to store different type of objects. "
            "As Active Directories change over time you can often find Organizational Units with linked GPOs and no objects inside. "
            "In some cases thats's expected, but in some cases it's totally unnessecary, and for very large AD can be a problem. "
            "Additionally only User and Computer objects can have GPO applied to them, so having GPO applied to a any other object type won't really work. "
        )
        New-HTMLText -FontSize 10pt -Text "Following can happen: " -FontWeight bold
        New-HTMLList -Type Unordered {
            New-HTMLListItem -Text 'Organizational Units that can have Group Policies unlinked (objects exists): ', $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPO'] -FontWeight normal, bold
            New-HTMLListItem -Text 'Organizational Units that can have Group Policies unlinked and OU removed (be careful!) (no objects): ', $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPODeleteOU'] -FontWeight normal, bold
            New-HTMLListItem -Text "Organizational Units that can be deleted (no objects/no gpos): ", $Script:Reporting['GPOOrganizationalUnit']['Variables']['DeleteOU'] -FontWeight normal, bold
        } -FontSize 10pt
        New-HTMLText -Text 'Following domains require actions (permissions required):' -FontSize 10pt -FontWeight bold
        New-HTMLList -Type Unordered {
            foreach ($Domain in $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'].Keys) {
                New-HTMLListItem -Text "$Domain requires ", $Script:Reporting['GPOOrganizationalUnit']['Variables']['WillFixPerDomain'][$Domain], " changes." -FontWeight normal, bold, normal
            }
        } -FontSize 10pt
        New-HTMLText -Text @(
            "Please make sure that you really want to unlink GPO or delete Organizational Unit before executing changes. Sometimes it's completly valid to keep one or the other. "
            "Unlinking GPO from OU that has no Computer or User objects is fairly safe exercise. Removing OU requires a bit more dive in, and should only be executed if you know what you're doing. "
        ) -FontWeight normal, bold -Color None, Red -FontSize 10pt
    }
    Solution       = {
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                & $Script:GPOConfiguration['GPOOrganizationalUnit']['Summary']
            }
            New-HTMLPanel {
                New-HTMLChart {
                    New-ChartBarOptions -Type bar -Distributed
                    New-ChartAxisY -LabelMaxWidth 200 -LabelAlign left -Show
                    New-ChartBar -Name "Unlink GPO ($($Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPO']))" -Value $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPO']
                    New-ChartBar -Name "Unlink GPO & Delete OU ($($Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPODeleteOU']))" -Value $Script:Reporting['GPOOrganizationalUnit']['Variables']['UnlinkGPODeleteOU']
                    New-ChartBar -Name "Delete OU ($($Script:Reporting['GPOOrganizationalUnit']['Variables']['DeleteOU']))" -Value $Script:Reporting['GPOOrganizationalUnit']['Variables']['DeleteOU']
                } -Title 'Organizational Units' -TitleAlignment center
            }
        }
        New-HTMLSection -Name 'Group Policy Organizational Units' {
            New-HTMLTable -DataTable $Script:Reporting['GPOOrganizationalUnit']['Data'] -Filtering {
                New-TableHeader -ResponsiveOperations none -Names 'GPONames', 'Objects'
                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Value 'Unlink GPO, Delete OU' -BackgroundColor Salmon -Row
                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Value 'Unlink GPO' -BackgroundColor YellowOrange -Row
                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Value 'Delete OU' -BackgroundColor Red -Row
                New-HTMLTableCondition -Name 'Status' -ComparisonType string -Value 'OK' -BackgroundColor LightGreen -Row
            } -PagingOptions 10, 20, 30, 40, 50 -SearchBuilder -ExcludeProperty GPO
        }
        if ($Script:Reporting['Settings']['HideSteps'] -eq $false) {
            New-HTMLSection -Name 'Steps to fix Group Organizational Units' {
                New-HTMLContainer {
                    New-HTMLSpanStyle -FontSize 10pt {
                        #New-HTMLText -Text 'Following steps will guide you how to fix group policy owners'
                        New-HTMLWizard {
                            New-HTMLWizardStep -Name 'Prepare environment' {
                                New-HTMLText -Text "To be able to execute actions in automated way please install required modules. Those modules will be installed straight from Microsoft PowerShell Gallery."
                                New-HTMLCodeBlock -Code {
                                    Install-Module GPOZaurr -Force
                                    Import-Module GPOZaurr -Force
                                } -Style powershell
                                New-HTMLText -Text "Using force makes sure newest version is downloaded from PowerShellGallery regardless of what is currently installed. Once installed you're ready for next step."
                            }
                            New-HTMLWizardStep -Name 'Prepare report' {
                                New-HTMLText -Text "Depending when this report was run you may want to prepare new report before proceeding with unlinking unused Group Policies. To generate new report please use:"
                                New-HTMLCodeBlock -Code {
                                    Invoke-GPOZaurr -FilePath $Env:UserProfile\Desktop\GPOZaurrGPOOrganizationalUnitBefore.html -Verbose -Type GPOOrganizationalUnit
                                }
                                New-HTMLText -TextBlock {
                                    "When executed it will take a while to generate all data and provide you with new report depending on size of environment."
                                    "Once confirmed that data is still showing issues and requires fixing please proceed with next step."
                                }
                                New-HTMLText -Text "Alternatively if you prefer working with console you can run: "
                                New-HTMLCodeBlock -Code {
                                    $OwnersGPO = Get-GPOZaurrOrganizationalUnit -Verbose
                                    $OwnersGPO | Format-Table
                                }
                                New-HTMLText -Text "It provides same data as you see in table above just doesn't prettify it for you."
                            }
                            New-HTMLWizardStep -Name 'Unlink unused Group Policies' {
                                New-HTMLText -Text @(
                                    "Following command when executed runs cleanup procedure that unlinks all Group Policies from Organizational Units that have no user or computer objects. "
                                    "Make sure when running it for the first time to run it with ",
                                    "WhatIf",
                                    " parameter as shown below to prevent accidental unlinking."
                                    'When run it will remove any GPO links from Organizational Units that have no objects applicable for GPOs.'
                                ) -FontWeight normal, normal, bold, normal -Color Black, Black, Red, Black
                                New-HTMLCodeBlock -Code {
                                    Remove-GPOZaurrLinkEmptyOU -WhatIf -Verbose
                                }
                                New-HTMLText -TextBlock {
                                    "Alternatively for multi-domain scenario, if you have limited Domain Admin credentials to a single domain please use following command: "
                                }
                                New-HTMLCodeBlock -Code {
                                    Remove-GPOZaurrLinkEmptyOU -WhatIf -Verbose -IncludeDomains 'YourDomainYouHavePermissionsFor'
                                }
                                New-HTMLText -TextBlock {
                                    "After execution please make sure there are no errors, make sure to review provided output, and confirm that what is about to be removed matches expected data. "
                                    "Keep in mind that there is no backup for this, and if link is removed you would need to relink it yourself."
                                    "Once you remove it, it's gone. "
                                } -LineBreak
                                New-HTMLText -Text 'Once happy with results please follow with command (this will start removal process): ' -LineBreak -FontWeight bold
                                New-HTMLCodeBlock -Code {
                                    Remove-GPOZaurrLinkEmptyOU -WhatIf -LimitProcessing 2 -Verbose
                                }
                                New-HTMLText -TextBlock {
                                    "Alternatively for multi-domain scenario, if you have limited Domain Admin credentials to a single domain please use following command: "
                                }
                                New-HTMLCodeBlock -Code {
                                    Remove-GPOZaurrLinkEmptyOU -WhatIf -LimitProcessing 2 -Verbose -IncludeDomains 'YourDomainYouHavePermissionsFor'
                                }
                                New-HTMLText -TextBlock {
                                    "This command when executed deletes only first X broken GPOs. Use LimitProcessing parameter to prevent mass delete and increase the counter when no errors occur. "
                                    "Repeat step above as much as needed increasing LimitProcessing count till there's nothing left. In case of any issues please review and action accordingly. "
                                } -LineBreak
                                New-HTMLText -TextBlock {
                                    "It's possible to exclude certain OU's from having GPO's unlinked using follwing method: "
                                } -FontWeight bold
                                New-HTMLCodeBlock -Code {
                                    $Exclude = @(
                                        "OU=Groups,OU=Production,DC=ad,DC=evotec,DC=pl"
                                        "OU=Test \, OU,OU=ITR02,DC=ad,DC=evotec,DC=xyz"
                                    )
                                    Remove-GPOZaurrLinkEmptyOU -Verbose -LimitProcessing 3 -WhatIf -ExcludeOrganizationalUnit $Exclude
                                }
                            }
                            New-HTMLWizardStep -Name 'Delete unused Organizational Units' {
                                New-HTMLText -Text @(
                                    "Following automation is not yet implemented. Requires more testing as potentially it could do more damage than help."
                                )
                            }
                            New-HTMLWizardStep -Name 'Verification report' {
                                New-HTMLText -TextBlock {
                                    "Once cleanup task was executed properly, we need to verify that report now shows no problems."
                                }
                                New-HTMLCodeBlock -Code {
                                    Invoke-GPOZaurr -FilePath $Env:UserProfile\Desktop\GPOZaurrGPOOrganizationalUnitAfter.html -Verbose -Type GPOOrganizationalUnit
                                }
                                New-HTMLText -Text "If everything is healthy in the report you're done! Enjoy rest of the day!" -Color BlueDiamond
                            }
                        } -RemoveDoneStepOnNavigateBack -Theme arrows -ToolbarButtonPosition center -EnableAllAnchors
                    }
                }
            }
        }
        if ($Script:Reporting['GPOOrganizationalUnit']['WarningsAndErrors']) {
            New-HTMLSection -Name 'Warnings & Errors to Review' {
                New-HTMLTable -DataTable $Script:Reporting['GPOOrganizationalUnit']['WarningsAndErrors'] -Filtering {
                    New-HTMLTableCondition -Name 'Type' -Value 'Warning' -BackgroundColor SandyBrown -ComparisonType string -Row
                    New-HTMLTableCondition -Name 'Type' -Value 'Error' -BackgroundColor Salmon -ComparisonType string -Row
                } -PagingOptions 10, 20, 30, 40, 50
            }
        }
    }
}