param (
    [object]$config,
    [Object]$SqlInstance,
    [SecureString]$SqlCredential,
    [String]$Database
)

$filename = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

$dbUsers = Get-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
$dbUserRoles = Get-DbaDbRoleMember -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database -IncludeSystemUser
$dbRoles = Get-DbaDbRole -SqlInstance $sqlinstance -SqlCredential $SqlCredential -Database $database 
Foreach ($case in $config) {
    Describe "Checking $($case.username)" {
        It "$($case.username) should exist" {
            $case.username | Should -BeIn $dbUsers.Name -Because "User Should exist"
        }

        Foreach ($role in $case.roles){
            It "$($case.username) should be a member of $role " {
                $role | Should -BeIn $dbUserRoles.Role
            }
        }

        $testRoles = $dbUserRoles | where-Object {$case.UserName -eq $_.UserName}
        ForEach ($role in $testRoles){
            It "$($case.username) Should be in $($role.Role)" {
                $role.Role | Should -BeIn $case.roles -Because "User should only be in the specified roles"
            }
        }

        # if ($_.Permissions.Count -ge 1) {
            $testPermissions =  Get-DbaUserPermission -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $database
            # Go through to check the specified permissions are there
            Foreach($permission in $case.Permissions){
                It "Should have assigned $($case.userName) $($permission.permission) on $($permission.object)" {
                    ($testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -eq $permission.object -and $_.permission -eq $permission.permission}).Count | Should -Be 1
                }

            }
            # Go through again to make sure no other permissions are there
            # Foreach ($permission in $testPermissions){
                It "Should not have assigned $($case.userName) $($permission.permission) on $($permission.object)" {
                    ($testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -notin ($case.permissions.object) -and $_.permission -notin ($case.permissions.permission)}).Count | Should -Be 0 -Because "Should only have defined permissions"
                }
                $testPermissions | Where-Object {$_.Grantee -eq $case.username -and $_.Securable -notin ($case.permissions.object) -and $_.permission -notin ($case.permissions.permission)}
            # }
        # }
    }
}