$script:DSCModuleName = 'xNetworking'
$script:DSCResourceName = 'MSFT_xNetAdapterRDMA'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[string] $script:moduleRoot = Join-Path -Path $(Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))) -ChildPath 'Modules\xNetworking'
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        # Create the Mock -CommandName Objects that will be used for running tests
        $testAdapterName = 'SMB1_1'
        $targetParameters = [PSObject] @{
            Name = $testAdapterName
        }

        $mockNetAdapterRDMAEnabled = [PSCustomObject] @{
            Name    = $testAdapterName
            Enabled = $true
        }

        $mockNetAdapterRDMADisabled = [PSCustomObject] @{
            Name    = $testAdapterName
            Enabled = $false
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            function Get-NetAdapterRdma
            {
            }

            Context 'Network adapter does not exist' {
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Get-TargetResource @targetParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Network Team exists' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMAEnabled }

                It 'Should return network adapter RDMA properties' {
                    $Result = Get-TargetResource @targetParameters
                    $Result.Name                   | Should -Be $targetParameters.Name
                    $Result.Enabled                | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            function Get-NetAdapterRdma
            {
            }
            function Set-NetAdapterRdma
            {
                param
                (
                    [Parameter(Mandatory = $true)]
                    [System.String]
                    $Name,

                    [Parameter(Mandatory = $true)]
                    [System.Boolean]
                    $Enabled = $true
                )
            }

            Context 'Net Adapter does not exist' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMAEnabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMADisabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $true
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is enabled and should be disabled' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMAEnabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $false
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                Mock -CommandName Set-NetAdapterRdma
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMADisabled }

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $targetParameters.Clone()
                    $setTargetResourceParameters['Enabled'] = $false
                    {
                        Set-TargetResource @setTargetResourceParameters
                    } | Should -Not -Throw
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                    Assert-MockCalled -CommandName Set-NetAdapterRdma -Exactly -Times 0
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            function Get-NetAdapterRdma
            {
            }

            Context 'Net Adapter does not exist' {
                Mock -CommandName Get-NetAdapterRdma -MockWith {
                    throw 'Network adapter not found'
                }

                It 'Should throw expected exception' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true

                    $errorRecord = Get-InvalidOperationRecord `
                        -Message ($LocalizedData.NetAdapterNotFoundError -f $testAdapterName)

                    {
                        Test-TargetResource @testTargetResourceParameters
                    } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already enabled and no action needed' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMAEnabled }

                It 'Should return true' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is disabled and should be enabled' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMADisabled }

                It 'Should return false' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $true
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is enabled and should be disabled' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMAEnabled }

                It 'Should return false' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $false
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }

            Context 'Net Adapter RDMA is already disabled and no action needed' {
                Mock -CommandName Get-NetAdapterRdma -MockWith { $mockNetAdapterRDMADisabled }

                It 'Should return true' {
                    $testTargetResourceParameters = $targetParameters.Clone()
                    $testTargetResourceParameters['Enabled'] = $false
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapterRdma -Exactly -Times 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
