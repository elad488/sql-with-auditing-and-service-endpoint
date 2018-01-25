<#
$credsAz = Get-Credential
try
{
    Add-AzureRmAccount -Credential $credsAz -ErrorAction Stop    
}
catch
{
    "Failed connecting to Azure"
    exit
}
#>
$hashLocation = @{
    eastasia = 'AE'
    southeastasia = 'AS'
    centralus = 'USC'
    eastus = 'USE'
    eastus2 = 'USE2'
    westus = 'USW'
    northcentralus = 'USNC'
    southcentralus = 'USSC'
    northeurope = 'EUN'
    westeurope = 'EUW'
    japanwest = 'JPW'
    japaneast = 'JPE'
    brazilsouth = 'BRS'
    australiaeast = 'AUA'
    australiasoutheast = 'AUSE'
    southindia = 'INS'
    centralindia = 'INC'
    westindia = 'INW'
    canadacentral = 'CAC'
    canadaeast = 'CAE'
    uksouth = 'UKS'
    ukwest = 'UKW'
    westcentralus = 'USWC'
    westus2 = 'USW2'
    koreacentral = 'KRC'
    koreasouth = 'KRS'
}

$objParametersProps = @{
    'ResourceGroup' = [string]
    'vNETName' = [string]
    'SubnetName' = [string]
    'DeploymentID' = [string]
    'Password' = [string]
    'Location' = [string]

}
$objParameters = New-Object -TypeName PSObject -Property $objParametersProps

$resourceGroup = Get-AzureRmResourceGroup | Where-Object{$_.Tags.Automation -eq $true}
$vNET = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup.ResourceGroupName | Where-Object{$_.Tag.Automation -eq $true}
$password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | Sort-Object {Get-Random})[0..11] -join '' |
    ConvertTo-SecureString -AsPlainText -Force

if($resourceGroup -and $vNET)
{
    $objParameters.ResourceGroup = $resourceGroup.ResourceGroupName
    $objParameters.vNETName = $vNET.Name
    $objParameters.SubnetName = $vNET.Subnets.Name
    $objParameters.DeploymentID = [guid]::NewGuid()
    $objParameters.Password = $password
    $objParameters.Location = $hashLocation.$($resourceGroup.Location)
}
else
{
    "Not enough information found"
    exit
}

$deploymentParams = @{
    Name = $($objParameters.DeploymentID)
    ResourceGroup = $($objParameters.ResourceGroup)
    TemplateFile = '/Users/mdavidov/Documents/Data/Sources/Automation/Infrastructure/Templates/Databases/SQL/createAzureSQL/azuredeploy.json'
    TemplateParameterFile = '/Users/mdavidov/Documents/Data/Sources/Automation/Infrastructure/Templates/Databases/SQL/createAzureSQL/azuredeploy.parameters.json'
    secSqlServerPwd = $($objParameters.Password)
    deploymentId = $($objParameters.DeploymentID)
    vnetName = $($objParameters.vNETName)
    subnetName = $($objParameters.SubnetName)
}

try
{
    [System.Collections.Hashtable]$hashResult = @{}
    $deploymentResult = New-AzureRmResourceGroupDeployment @deploymentParams
    $deploymentResult.Outputs.Keys | ForEach-Object{$hashResult.add($_,$result.Outputs.$_.Value)}

}
catch
{
    "ARM template deployment failed. DeploymentID: {0}" -f $($objParameters.DeploymentID)
}