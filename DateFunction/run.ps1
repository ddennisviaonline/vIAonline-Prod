param($Request, $TriggerMetadata)

# Importar el script date.ps1
. $PSScriptRoot\date.ps1

# Llamar a la función definida en date.ps1
$message = Get-DateMessage

$body = @{ message = $message } | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $body
})
