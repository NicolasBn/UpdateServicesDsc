$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Modules\DscResource.Common'
Import-Module -Name $script:resourceHelperModulePath -ErrorAction Stop
Import-Module -Name WindowsUpdateProvider -ErrorAction Stop
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US' -FileName 'UpdateServicesDSC.Common.strings.psd1'

function Get-UpdateServicesDscProduct
{
    [OutputType('Microsoft.UpdateServices.Administration.UpdateCategoryCollection')]
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string[]]$ProductsList,

        [parameter(Mandatory = $true)]
        [Microsoft.UpdateServices.Internal.BaseApi.UpdateServer]$WsusServer
    )

    $productCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
    $allWsusProducts = $WsusServer.GetUpdateCategories()

    switch ($ProductsList)
    {
        # All Products
        '*' {
            Write-Verbose -Message $script:localizedData.GetAllProducts
            foreach ($Prdct in $allWsusProducts)
            {
                $null = $productCollection.Add($WsusServer.GetUpdateCategory($Prdct.Id))
            }
            continue
        }
        # if Products property contains wildcard like "Windows*"
        {[System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($_)} {
            $wildcardPrdct = $_
            Write-Verbose -Message $($script:localizedData.GetWildcardProducts -f $wildcardPrdct)
            if ($wsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -like $wildcardPrdct })
            {
                foreach ($prdct in $wsusProduct)
                {
                    $null = $productCollection.Add($WsusServer.GetUpdateCategory($prdct.Id))
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.NoWildcardProductFound
            }
            continue
        }

        <#
            We can try to add GUID support for product with :

            $StringGuid ="077e4982-4dd1-4d1f-ba18-d36e419971c1"
            $ObjectGuid = [System.Guid]::New($StringGuid)
            $IsEmptyGUID = $ObjectGuid -eq [System.Guid]::empty

            Maybe with function
        #>

        default {
            Write-Verbose -Message $($script:localizedData.GetNameProduct -f $_)
            $prdct = $_
            if ($WsusProduct = $allWsusProducts | Where-Object -FilterScript { $_.Title -eq $prdct })
            {
                foreach ($pdt in $WsusProduct)
                {
                    $null = $productCollection.Add($WsusServer.GetUpdateCategory($pdt.Id))
                }
            }
            else
            {
                Write-Verbose -Message $script:localizedData.NoNameProductFound
            }
        }
    }

    Write-Output $productCollection -NoEnumerate
}

Export-ModuleMember Get-UpdateServicesDscProduct
