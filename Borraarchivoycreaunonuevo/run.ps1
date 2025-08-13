param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN ====
$owner    = "ddennisviaonline"
$repo     = "vIAonline-Prod"
$filePath = "lista.csv"
$branch   = "master"
$token    = $env:GitHubTokenFull

# ==== ENCABEZADOS PARA GITHUB ====
$headers = @{
    Authorization = "token $token"
    "User-Agent"  = "AzureFunction"
}

# ==== OBTENER SHA DEL ARCHIVO ====
try {
    $shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath?ref=$branch"
    $fileInfo = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method GET
    $sha = $fileInfo.sha
} catch {
    # Si no existe, devolvemos mensaje y salimos
    $response = @{
        status = "Archivo no existe"
        file   = $filePath
    } | ConvertTo-Json
    Write-Output $response
    exit
}

# ==== BORRAR EL ARCHIVO ====
$deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
$deleteBody = @{
    message = "Borrando archivo desde Azure Function"
    sha     = $sha
    branch  = $branch
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method DELETE -Body $deleteBody

# ==== RESPUESTA ====
$response = @{
    status = "Archivo borrado exitosamente"
    file   = $filePath
} | ConvertTo-Json

Write-Output $response


