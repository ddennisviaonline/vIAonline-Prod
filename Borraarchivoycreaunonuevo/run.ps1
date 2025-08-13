param($Request, $TriggerMetadata)

# Parsear el cuerpo JSON para obtener archivo, si no viene usar valor por defecto
try {
    $data = $Request.Body | ConvertFrom-Json
    $filePath = if ($data.filePath) { $data.filePath } else { "lista.csv" }
} catch {
    $filePath = "lista.csv"
}

# Configuración
$owner  = "ddennisviaonline"
$repo   = "vIAonline-Prod"
$branch = "main"
$token  = $env:GitHubTokenFull

# Headers para GitHub
$headers = @{
    Authorization = "token $token"
    "User-Agent"  = "AzureFunction"
}

try {
    # Obtener SHA del archivo
    $shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath?ref=$branch"
    $fileInfo = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method GET
    $sha = $fileInfo.sha

    if (-not $sha) {
        throw "No se encontró SHA para el archivo."
    }

    # Preparar cuerpo para borrar archivo
    $deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
    $deleteBody = @{
        message = "Borrando archivo desde Azure Function"
        sha     = $sha
        branch  = $branch
    } | ConvertTo-Json -Depth 3

    # Ejecutar DELETE
    Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method DELETE -Body $deleteBody

    $response = @{
        status = "Archivo borrado exitosamente"
        file   = $filePath
    }

} catch {
    $response = @{
        status = "Error al borrar archivo"
        error  = $_.Exception.Message
        file   = $filePath
    }
}

# Retornar JSON
$response | ConvertTo-Json
