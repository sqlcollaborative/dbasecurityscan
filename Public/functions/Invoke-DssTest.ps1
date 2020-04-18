function Invoke-DssTest {
    <#
    .SYNOPSIS
        Runs the specified tests against the specified database(s)
    
    .PARAMETER SqlInstance

    .PARAMETER SqlCredential

    .PARAMETER ConfigPath

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath c:\tests\config.json

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath http://github.com/someone/SqlTest/raw/config.json

    .EXAMPLE
        Invoke-DssTest -SqlInstance localhost -ConfigPath c:\tests\secrets.json, http://github.com/someone/SqlTest/raw/config.json

    .EXAMPLE
        $Output = Invoke-DssTest -SqlInstance localhost -Config $config -Output -Quiet

    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [string[]]$ConfigPath,
        [string]$SqlInstance,
        [PSCredential]$SqlCredential,
        [string]$Database,
        [switch]$UserConfig,
        [switch]$RoleConfig,
        [switch]$SchemaConfig,
        [switch]$ObjectConfig,
        [switch]$NoOutput,
        [object]$Config,
        [switch]$Quiet,
        [switch]$IncludeSystemObjects
    )
    begin {

    }
    process {
        $configSwitch = $true
        if ($UserConfig -eq $True -or $SchemaConfig -eq $True -or $RoleConfig -eq $True -or $ObjectConfig -eq $True) {
            $configSwitch = $false
        }

        if ($Quiet -eq $true) {
            $show = 'None'
        } else {
            $show = 'All'
        }

        if ($UserConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Testing User config"
            $usersResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Users.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} } -PassThru -Show $show
        } 
        if ($RoleConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Testing Role config"
            $rolesResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Roles.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} } -PassThru -Show $show
        } 
        if ($SchemaConfig -eq $True -or $configSwitch) {
            Write-Verbose -Message "Testing Schema config"
            $schemaResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Schemas.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database; IncludeSystemObjects = $IncludeSystemObjects } } -PassThru -Show $show
        } 
        if ($ObjectConfig -eq $True  -or $configSwitch) {
            Write-Verbose -Message "Testing Object config"
            $objectResults = Invoke-Pester -Script @{ Path = "$Script:dssmoduleroot\Checks\Objects.Tests.ps1"; Parameters = @{SqlInstance = $sqlInstance; SqlCredential = $sqlCredential; Config = $config; Database = $database} } -PassThru -Show $show
        }
        if ($NoOutput -ne $true){
            [PSCustomObject]@{
                usersResults    = $usersResults
                rolesResults    = $rolesResults
                schemaResults   = $schemaResults
                objectRestults  = $objectResults
            }
        }
    }
    end {}
}