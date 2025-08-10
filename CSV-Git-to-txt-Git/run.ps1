# Descarga un archivo csv ubicado en la carpeta main de github y descarga un txt en la carpeta master de github
param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"  # Ejemplo: "datos/archivo.csv"
$txtPath = "archivo.txt"
$branchSource = "main"
$branch = "master"
$token = $env:GitHubToken

# ==== 1. DESCARGAR CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchSource/$csvPath"
try {
    $csvContent = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" }
    # Si quieres procesar el CSV como tabla:
    $csvData = $csvContent | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}

# ==== 2. LÓGICA (ejemplo simple) ====
# Aquí podrías procesar los datos del CSV. Ejemplo: contar registros
$lineas = $csvData.Count
$fileContent = "El archivo CSV tiene $lineas filas. Generado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')."

# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$txtPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar contenido en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# Crear body para PUT
$body = @{
    message = "Archivo TXT generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$txtPath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# Respuesta HTTP
$bodyOut = @{
    message = "TXT generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})
