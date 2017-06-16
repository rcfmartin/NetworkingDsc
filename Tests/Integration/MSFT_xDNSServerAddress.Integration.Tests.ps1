$script:DSCModuleName      = 'xNetworking'
$script:DSCResourceName    = 'MSFT_xDNSServerAddress'

#region HEADER
# Integration Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Integration
#endregion

# Load the Integration Helper
. (Join-Path -Path (Split-Path -Parent $Script:MyInvocation.MyCommand.Path) -ChildPath 'IntegrationHelper.ps1')

# Configure Loopback Adapter
$adapterName = 'xNetworkingLBA'
New-IntegrationLoopbackAdapter -AdapterName $adapterName

# Using try/finally to always cleanup even if something awful happens.
try
{
    #region Integration Tests
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_Static.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration using single address" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName             = 'localhost'
                            InterfaceAlias       = $adapterName
                            AddressFamily        = 'IPv4'
                            Address              = '10.139.17.99'
                            Validate             = $False
                        }
                    )
                }

                & "$($script:DSCResourceName)_Config_Static" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq "$($script:DSCResourceName)_Config_Static"}
            $current.InterfaceAlias             | Should Be $adapterName
            $current.AddressFamily              | Should Be 'IPv4'
            $current.Address.Count              | Should Be 1
            $current.Address                    | Should Be '10.139.17.99'
        }
        #endregion
    }

    Describe "$($script:DSCResourceName)_Integration using two addresses" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName             = 'localhost'
                            InterfaceAlias       = $adapterName
                            AddressFamily        = 'IPv4'
                            Address              = @('10.139.17.99','10.139.17.100')
                            Validate             = $False
                        }
                    )
                }

                & "$($script:DSCResourceName)_Config_Static" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq "$($script:DSCResourceName)_Config_Static"}
            $current.InterfaceAlias             | Should Be $adapterName
            $current.AddressFamily              | Should Be 'IPv4'
            $current.Address.Count              | Should Be 2
            $current.Address[0]                 | Should Be '10.139.17.99'
            $current.Address[1]                 | Should Be '10.139.17.100'
        }
        #endregion
    }

    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$($script:DSCResourceName)_DHCP.config.ps1"
    . $ConfigFile -Verbose -ErrorAction Stop

    Describe "$($script:DSCResourceName)_Integration using no addresses" {
        #region DEFAULT TESTS
        It 'Should compile and apply the MOF without throwing' {
            {
                # This is to pass to the Config
                $configData = @{
                    AllNodes = @(
                        @{
                            NodeName             = 'localhost'
                            InterfaceAlias       = $adapterName
                            AddressFamily        = 'IPv4'
                        }
                    )
                }

                & "$($script:DSCResourceName)_Config_DHCP" `
                    -OutputPath $TestDrive `
                    -ConfigurationData $configData
                Start-DscConfiguration -Path $TestDrive `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'Should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }

        It 'Should have set the resource and all the parameters should match' {
            $current = Get-DscConfiguration | Where-Object {$_.ConfigurationName -eq "$($script:DSCResourceName)_Config_DHCP"}
            $current.InterfaceAlias             | Should Be $adapterName
            $current.AddressFamily              | Should Be 'IPv4'
            $current.Address.Count              | Should Be 0
            $current.Address                    | Should BeNullOrEmpty
        }
        #endregion
    }
    #endregion
}
finally
{
    # Remove Loopback Adapter
    Remove-IntegrationLoopbackAdapter -AdapterName $adapterName

    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
