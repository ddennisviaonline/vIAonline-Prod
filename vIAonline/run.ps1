param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$newCsvPath = "caba.csv"  # CSV final en rama master
$branch = "master"
$token = $env:GitHubToken

# ==== 1. DESCARGAR ZIP DEL SMN ====
$tempFolder = Join-Path $env:TEMP "smnzip"
$zipFile    = Join-Path $tempFolder "smn.zip"

# Limpia carpeta temporal
if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force }
New-Item -Path $tempFolder -ItemType Directory | Out-Null

Invoke-WebRequest -Uri "https://ssl.smn.gob.ar/dpd/zipopendata.php?dato=tiepre" -OutFile $zipFile

# ==== 2. EXTRAER ZIP ====
Expand-Archive -Path $zipFile -DestinationPath $tempFolder

# ==== 3. LEER Y UNIR TXT ====
$txtFiles = Get-ChildItem -Path $tempFolder -Filter *.txt
if (-not $txtFiles) { throw "No se encontraron archivos TXT en el ZIP." }

# Lee headers desde el primer archivo
$headers = (Get-Content $txtFiles[0].FullName)[0]
$csvLines = @($headers)

foreach ($file in $txtFiles) {
    $csvLines += Get-Content $file.FullName | Select-Object -Skip 1
}

# ==== 4. CONVERTIR A OBJETO Y FILTRAR AEROPARQUE ====
$csvData = ($csvLines -join "`n") | ConvertFrom-Csv -Delimiter ';'
$record = $csvData | Where-Object { $_.Ciudad -match '^Aeroparque' } | Select-Object -First 1

if (-not $record) { throw "No se encontró información para Aeroparque." }

# Preparamos un CSV con una sola fila
$resultObject = [PSCustomObject]@{
    Ciudad       = "CABA"
    Temperatura  = "$($record.Temperatura)º"
    Estado       = ($record.EstadoDelCielo.Split(" ")[0])
    Fecha        = $record.Fecha
    Hora         = $record.Hora
}

$fileContent = $resultObject | ConvertTo-Csv -NoTypeInformation

# ==== 5. SUBIR CSV A GITHUB ====
# Obtener SHA si ya existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$newCsvPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar contenido a Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent -join "`n"))

# Crear body para PUT
$body = @{
    message = "CSV CABA generado desde Azure Function"
    content = $contentBase64
    branch  = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$newCsvPath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# ==== 6. RESPUESTA HTTP ====
$bodyOut = @{
    message   = "CSV de CABA generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body       = $bodyOut
})
