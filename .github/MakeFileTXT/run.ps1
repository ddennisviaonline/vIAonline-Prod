param($Request, $TriggerMetadata)

# Contenido para el archivo TXT
$fileContent = "Este es un archivo generado desde Azure Function el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Parámetros del repo GitHub
$owner = "tu_usuario_o_org"
$repo = "tu_repositorio"
$path = "ruta/del/archivo/archivo.txt"  # Ejemplo: "archivos/archivo.txt"
$branch = "main"

# Token almacenado en Application Settings
$token = $env:GitHubToken

# Obtener SHA del archivo para actualizarlo (si existe)
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    # El archivo no existe, no se necesita sha
    $sha = $null
}

# Codificar contenido en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# Crear cuerpo para el PUT (crear o actualizar)
$body = @{
    message = "Creación o actualización archivo desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }

$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo al repo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$path"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# Respuesta
$bodyOut = @{
    message = "Archivo TXT guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})
