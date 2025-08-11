param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"       # CSV de origen (rama main)
$newCsvPath = "archivo.csv"  # CSV que vamos a subir (rama master)
$branchsource = "main"
$branch = "master"
$token = $env:GitHubToken

# ==== 1. DESCARGAR CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchsource/$csvPath"
try {
    $csvData = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" } | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}

# ==== 2. LÓGICA: EJEMPLO ====
# Supongamos que agregamos una columna con la fecha de procesamiento
$csvProcesado = $csvData | ForEach-Object {
    $_ | Add-Member -NotePropertyName "FechaProcesado" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
    $_
}

# Convertimos el objeto a formato CSV (sin el tipo de objeto en la 1° línea)
$fileContent = $csvProcesado | ConvertTo-Csv -NoTypeInformation

# ==== 3. SUBIR CSV A GITHUB ====
# Obtener SHA si ya existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$newCsvPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar contenido en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent -join "`n"))

# Crear body para PUT
$body = @{
    message = "CSV generado desde Azure Function"
    content = $contentBase64
    branch  = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$newCsvPath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# Respuesta HTTP
$bodyOut = @{
    message   = "CSV generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body       = $bodyOut
})
