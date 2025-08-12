param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"           # Ruta del CSV en main
$csvOutputPath = "listaOUTPUT.csv"   # Ruta/nombre del CSV en master
$branchsource = "main"           # Rama origen
$branch = "master"               # Rama destino
$token = $env:GitHubToken

if (-not $token) {
    throw "El token de GitHub no está definido en la variable de entorno GitHubToken."
}

# ==== 1. DESCARGAR CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchsource/$csvPath"
try {
    $csvContentRaw = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" } -Method GET
    $csvData = $csvContentRaw | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}

# ==== 2. CONVERTIR EL CSV A TEXTO EN MEMORIA ====
$fileContent = $csvData | ConvertTo-Csv -NoTypeInformation | Out-String

if ([string]::IsNullOrWhiteSpace($fileContent)) {
    throw "El contenido CSV está vacío, no se puede subir a GitHub."
}

# ==== 3. OBTENER SHA SI EL ARCHIVO YA EXISTE ====
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    # Si no existe el archivo o hay otro error, asumimos que no hay sha
    $sha = $null
}

# ==== 4. CODIFICAR A BASE64 ====
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# ==== 5. CREAR BODY PARA PUT ====
$body = @{
    message = "CSV copiado desde main a master por Azure Function"
    content = $contentBase64
    branch = $branch
}

if ($sha) {
    $body.sha = $sha
}

$jsonBody = $body | ConvertTo-Json -Depth 10

# ==== 6. SUBIR ARCHIVO A GITHUB ====
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath"
try {
    $responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody
} catch {
    throw "Error al subir el archivo a GitHub: $_"
}

# ==== 7. RESPUESTA HTTP ====
$bodyOut = @{
    message = "CSV copiado correctamente de main a master"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})
