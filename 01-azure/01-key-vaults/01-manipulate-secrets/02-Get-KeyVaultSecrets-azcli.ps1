param(
    [string]$SubscriptionID,
    $keyVaultPrimario = "dev-keyvault-rgdevelop",
    $keyVaultSecundario = "dev-kv-secundario",
    $diretorioSaida = ".\arquivo.json",
    [string]$AzureUserName, 
    [SecureString]$AzurePassword
)

function SelectSubscription {
    Write-Host "Selecting subscription '$SubscriptionID'";
    az account set --subscription $SubscriptionID;
}

function Login {

    if ($AzureUserName) {
        Write-Host "Logging in...";

        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzurePassword))

        az login -u $AzureUserName -p $password --allow-no-subscriptions

        SelectSubscription
        
    } else {
        az login
        SelectSubscription
    }

}

Login

$Secrets = New-Object System.Collections.ArrayList
function PreencherKeyVault {
    param($keyVaultName, $tipoKeyVault)

    $keyVaultSecrets = az keyvault secret list --vault-name $keyVaultName --query "[].id" --output tsv
}