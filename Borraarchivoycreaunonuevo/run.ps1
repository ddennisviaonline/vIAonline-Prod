param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN ====
$owner    = "ddennisviaonline"
$repo     = "vIAonline-Prod"
$filePath = "lista.csv"
$branch   = "main"
$token    = $env:GitHubToken

# ==== ENCABEZADOS PARA GITHUB ====
$headers = @{
    Authorization = "token $token"
    "User-Agent"  = "AzureFunction"
}

# ==== OBTENER SHA DEL ARCHIVO (si existe) ====
$sha = $null
try {
    $shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath?ref=$branch"
    $fileInfo = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method GET
    $sha = $fileInfo.sha
} catch {
    $sha = $null
}

# ==== CREAR NUEVO CONTENIDO ====
$newContent = "col1,col2,col3`nvalor1,valor2,valor3"
$encodedContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($newContent))

# ==== SUBIR EL ARCHIVO ====
$uploadUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
$uploadBody = @{
    message = "Actualizando archivo desde Azure Function"
    content = $encodedContent
    branch  = $branch
}

# Si existe, incluimos el sha para reemplazar
if ($sha) {
    $uploadBody.sha = $sha
}

$uploadBodyJson = $uploadBody | ConvertTo-Json -Depth 3
Invoke-RestMethod -Uri $uploadUrl -Headers $headers -Method PUT -Body $uploadBodyJson

# ==== RESPUESTA ====
@{
    status = "Archivo subido/reemplazado exitosamente"
    file   = $filePath
} | ConvertTo-Json

