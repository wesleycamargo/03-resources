
param(
    [string]$SubscriptionID,
    $keyVaultPrimario = "dev-keyvault-rgdevelop",
    $keyVaultSecundario = "dev-kv-secundario",
    $diretorioSaida = ".\arquivo.json",
    [string]$AzureUserName, 
    [SecureString]$AzurePassword
)

function SelectSubscription {
    Write-Host "Selecting subscription '$subscriptionId'";
    Select-AzureRmSubscription -SubscriptionID $subscriptionId;
}

function Login {

    if ($AzureUserName) {
        # sign in
        Write-Host "Logging in...";

        if ($AzurePassword) {
            $SecurePassword = ConvertTo-SecureString $AzurePassword -AsPlainText -Force
        }
        else {       
            $SecurePassword = Read-Host -AsSecureString "Enter your password"
        }

        $cred = new-object -typename System.Management.Automation.PSCredential `
            -argumentlist $AzureUserName, $SecurePassword

        Login-AzureRmAccount -Credential $cred

        SelectSubscription
        
    }

}

Login

$Secrets = New-Object System.Collections.ArrayList
function PreencherKeyVault {
    param($keyVaultName, $tipoKeyVault)

    $keyVaultSecrets = Get-AzureKeyVaultSecret -VaultName $keyVaultName

    foreach ($secret in $keyVaultSecrets) {
        Write-Host "KeyVault: $keyVaultName - Adicionando chave $($secret.Name)"
        $kvsecret = @{'KeyVault' = $keyVaultName;
            'Key'                = $secret.Name;
            'Value'              = (Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $secret.name).SecretValueText
        }

        $kvObject = New-Object PSObject -Property $kvsecret
        $Secrets.Add($kvObject)
    }

}


try {
    
    PreencherKeyVault -keyVaultName $keyVaultPrimario
    PreencherKeyVault -keyVaultName $keyVaultSecundario

    $Secrets | ConvertTo-Json > $diretorioSaida

}
catch {
    Write-Error $_.Exception.Message
}
