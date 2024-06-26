Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionId f009812d-0fd6-4064-812e-ad76471d0082

$keyVaultName = "dev-keyvault-conectcar"

$keys = Get-AzureKeyVaultSecret -VaultName $keyVaultName

$resourceFiles = New-Object System.Collections.ArrayList($null)

$resourceFiles.Add("|Key   |Value")
$resourceFiles.Add("|-   |-")

foreach ($key in $keys) {
     $temp = "|$($key.Name) " + "|" + (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $key.name).SecretValueText
     $resourceFiles.Add($temp)
}

$resourceFiles > .\arquivotexto.txt
