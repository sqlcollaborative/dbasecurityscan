param (
    $Show = "None"
)

Write-Host "Starting Tests" -ForegroundColor Green
if ($env:BUILD_BUILDURI -like "vstfs*") {
    Write-Host "Installing Pester" -ForegroundColor Cyan
    Install-Module Pester -Force -SkipPublisherCheck
    Write-Host "Installing PSFramework" -ForegroundColor Cyan
    Install-Module PSFramework -Force -SkipPublisherCheck
    Write-Host "Installing dbatools" -ForegroundColor Cyan
    Install-Module dbatools -Force
}

Write-Host "Loading constants"
. "$PSScriptRoot\constants.ps1"

Write-Host "Building Test Scenarios"
$sqlInstance = 'localhost\sql2017'
ForEach ($file in (Get-ChildItem "$PSScriptRoot\scenarios" -File -Filter "*.sql" -recurse)){
    (& sqlcmd -S "$sqlInstance" -U "sa" -P "Password12!" -b -i "$($file.fullname)" -d "master")
}
Write-Host "Importing dbaSecurityScans"
Import-Module "$PSScriptRoot\..\dbaSecurityScan.psd1"

$totalFailed = 0
$totalRun = 0

$testresults = @()
Write-Host "Running individual tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot" -File -Filter "*.Tests.ps1" -Recurse)) {
    Write-Host "Executing $($file.Name)"
    $results = Invoke-Pester -Script $file.FullName -Show None -PassThru
    foreach ($result in $results) {
        $totalRun += $result.TotalCount
        $totalFailed += $result.FailedCount
        $result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
            $name = $_.Name
            $testresults += [pscustomobject]@{
                Describe = $_.Describe
                Context  = $_.Context
                Name     = "It $name"
                Result   = $_.Result
                Message  = $_.FailureMessage
            }
        }
    }
}

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -gt 0) {
    throw "$totalFailed / $totalRun tests failed"
}