param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN ====
$owner    = "ddennisviaonline"
$repo     = "vIAonline-Prod"
$filePath = "lista.csv"   # Ruta en el repo
$branch   = "main"
$token    = $env:GitHubToken  # Guardado en Azure Function → Configuration

# ==== ENCABEZADOS PARA GITHUB ====
$headers = @{
    Authorization = "token $token"
    "User-Agent"  = "AzureFunction"
}

# ==== OBTENER SHA DEL ARCHIVO (si existe) ====
try {
    $shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath?ref=$branch"
    $fileInfo = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method GET
    $sha = $fileInfo.sha
} catch {
    $sha = $null
}

# ==== SI EXISTE, ELIMINARLO ====
if ($sha) {
    $deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
    $deleteBody = @{
        message = "Eliminando archivo antes de actualizar"
        sha     = $sha
        branch  = $branch
    } | ConvertTo-Json -Depth 3

    Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method DELETE -Body $deleteBody
}

# ==== CREAR NUEVO CONTENIDO ====
$newContent = "col1,col2,col3`nvalor1,valor2,valor3"
$encodedContent = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($newContent))

# ==== SUBIR EL NUEVO ARCHIVO ====
$uploadUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
$uploadBody = @{
    message = "Subiendo nuevo archivo desde Azure Function"
    content = $encodedContent
    branch  = $branch
} | ConvertTo-Json -Depth 3

Invoke-RestMethod -Uri $uploadUrl -Headers $headers -Method PUT -Body $uploadBody

# ==== RESPUESTA ====
@{
    status = "Archivo reemplazado exitosamente"
    file   = $filePath
} | ConvertTo-Json
