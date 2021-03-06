$commandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-host "importing $PSScriptRoot\constants.ps1 "
. "$PSScriptRoot\constants.ps1"

Describe "Unit tests for $commandName" {
    It "$commandName Should Exist" {
        (Get-Command -Module dbaSecurityScan | Where-Object {$_.Name -eq $commandName}).count | Should -Be 1
    }
}

Describe "Integration Tests for $commandName" {
    $config = New-DssObjectConfig -SqlInstance $script:appvSqlInstance -SqlCredential $script:appvSqlCredential -Database objects1

    It "Should have Objects" {
        ($config | Measure-Object).count | Should -Be 2
    }

    $pConfig = [PsCustomObject]@{
        Objects = $config
    }

    It "Should Test db properly" {
        $pesterOut = Invoke-Pester -Script @{ Path = "$PSScriptRoot\..\Checks\Objects.Tests.ps1"; Parameters = @{SqlInstance = $script:appvSqlInstance; Config = $pConfig; SqlCredential = $script:appvSqlCredential; Database = "objects1"} } -PassThru
        $pesterOut.PassedCount | Should -Be $pesterOut.TotalCount
    }
}