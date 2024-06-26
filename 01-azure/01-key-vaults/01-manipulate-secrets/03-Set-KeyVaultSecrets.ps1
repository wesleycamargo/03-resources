
param(
    [string]$SubscriptionID,
    $keyVaultPrimario = "dev-keyvault-rgdevelop",
    $keyVaultSecundario = "dev-kv-secundario",
    $configurationFile = ".\keys.json",
    [string]$AzureUserName, 
    [SecureString]$AzurePassword,
    [boolean]$ForceUpdate = $false
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

    Login
    
    $keys = Get-Content -Raw -Path $configurationFile  | ConvertFrom-Json

    PreencherKeyVault -keyVaultName $keyVaultPrimario
    PreencherKeyVault -keyVaultName $keyVaultSecundario

    $keysNaoAtualizadas = New-Object System.Collections.ArrayList

    foreach ($key in $keys) {
        Write-Host "Verificando chave: $($key.Key)"
        $chaveExistente = $false
        
        foreach ($secretExistente in $Secrets) {
           
            if ($key.Key -eq $secretExistente.Key) {
                $chaveExistente = $true
                if ($key.Value -eq $secretExistente.Value) {
                    break 
                }
                else {
                    if ($ForceUpdate -and $keys.Count -eq 1) {
                        if ($secretExistente.KeyVault -eq $keyVaultPrimario) {
                            $Secret = ConvertTo-SecureString -String $key.Value -AsPlainText -Force
                            Set-AzureKeyVaultSecret -VaultName $keyVaultPrimario -Name $key.key -SecretValue $Secret
                            Write-Host "Atualizando KeyVault Primario: $keyVaultPrimario"
                            break
                        }
                        elseif ($secretExistente.KeyVault -eq $keyVaultSecundario) {
                            $Secret = ConvertTo-SecureString -String $key.Value -AsPlainText -Force
                            Set-AzureKeyVaultSecret -VaultName $keyVaultSecundario -Name $key.key -SecretValue $Secret
                            Write-Host "Atualizando KeyVault Secundario: $keyVaultSecundario"
                            break               
                        }
                    }
                    else {
                        Write-Warning "Para atualizacao de chaves e necessario o parametro 'ForceUpdate' e deve ser especificada apenas uma chave no arquivo de configuracao" 
                        $keysNaoAtualizadas.Add($key) 
                    }
                }
            }
        }

        if (-Not $chaveExistente) {
            Write-Host "Chave inexistente. Realizando validacao de valores duplicados..."
            
            foreach ($secretExistente in $Secrets | Where { $_.KeyVault -eq $keyVaultPrimario } ) {
                if ($key.Value -eq $secretExistente.Value) {
                    Write-Host "Encontrado uma chave com o mesmo valor ja adicionado. Adicionando chave '$($key.name)' ao KeyVault secundario"
                    $token = "`$($($secretExistente.Key))"

                    $Secret = ConvertTo-SecureString -String $token -AsPlainText -Force
                    Set-AzureKeyVaultSecret -VaultName $keyVaultSecundario -Name $key.key -SecretValue $Secret
                    $chaveExistente = $true
                    break
                }
            }

            if (-Not $chaveExistente) {
                Write-Host "Não foi encontrado nenhuma chave com este valor ja adicionado. Adicionando chave '$($key.name)' ao KeyVault primario"
                $Secret = ConvertTo-SecureString -String $key.Value -AsPlainText -Force
                Set-AzureKeyVaultSecret -VaultName $keyVaultPrimario -Name $key.key -SecretValue $Secret
            }
        }
    }

    if ($keysNaoAtualizadas.Count -gt 0) {
        Write-Warning "Keys nao atualizadas:"
        $keysNaoAtualizadas | ConvertTo-Json
    }
}
catch {
    Write-Error $_.Exception.Message
}
