
# Make sure to run Connect-AzAccount first

using namespace Microsoft.Azure.Commands.KeyVault.Models

# input parameters to script
param( 
	[Parameter(Mandatory=$true)][string]$keyVaultName
)

function Get-SecretValue {

	param(
		[PSKeyVaultSecretIdentityItem]$secret
	)
	
	$secretValueText = '';
	$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.SecretValue)
	try {
		$secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
	} finally {
		[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
	}
	return $secretValueText
}

if ([string]::IsNullOrWhiteSpace($keyVaultName)) {
	Write-Error "Key vault name is required." -ForegroundColor Red -ErrorAction Stop
}

$values = @{}

try {
$secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName
}
catch [WebException] {
	Write-Error -Message "Error fetching key vault. Are you sure it exists?" $PSItem.Exception.ErrorCode -ErrorAction Stop
}
catch {
	Write-Host "Error fetching key vault."
	return
}

foreach($secret in $secrets)
{
	$secureValue = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secret.Name
	$plainTextValue = Get-SecretValue($secureValue)
	Write-Host "Fetching" $secret.Name
	$values.add($secret.Name, $plainTextValue)
}

$json = ConvertTo-Json -Depth 1 -InputObject $values
$jsonFilename = "$($keyVaultName).Azure.json"

Out-File -FilePath $jsonFilename -InputObject $json -Encoding UTF8
Write-Host "Dumped to" $jsonFilename -ForegroundColor Green