# MODULO CLIMA AEROPARQUE
# Descarga un archivo csv ubicado en la carpeta main de github y descarga un txt en la carpeta master de github
param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"  # Ejemplo: "datos/archivo.csv"
$txtPath = "archivo.csv"
$branchsource = "main" # powershell
$branch = "master" # webpage
$token = $env:GitHubToken

 Invoke-WebRequest -Uri "https://ssl.smn.gob.ar/dpd/zipopendata.php?dato=tiepre" -OutFile $zipFile

    # Extrae ZIP
    Expand-Archive -Path $zipFile -DestinationPath $Dir -Force

    # Headers CSV
    $headers = "Ciudad;Fecha;Hora;EstadoDelCielo;Visibilidad;Temperatura;PuntoDew;Humedad;Viento;Presion"

    # Lee todos los TXT y concatena contenido con headers
    $txtFiles = Get-ChildItem -Path $Dir -Filter *.txt
    $csvLines = @($headers)
    foreach ($file in $txtFiles) {
        $csvLines += Get-Content $file.FullName
    }
    # Convierte array de líneas a una cadena con saltos de línea
    $csvString = $csvLines -join "`n"

    # Importa CSV desde string con delimitador ';'
    $csvData = $csvString | ConvertFrom-Csv -Delimiter ';'

    # Filtra Aeroparque
    $record = $csvData | Where-Object { $_.Ciudad -match '^Aeroparque' } | Select-Object -First 1
    if (-not $record) { throw "No se encontró información para Aeroparque." }

    $estado = $record.EstadoDelCielo
    $primeraPalabra = $estado.Split(" ")[0]
    $fileContent= "CABA, $($record.Temperatura)º $primeraPalabra"




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
#$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# Crear body para PUT
$body = @{
    message = "Archivo TXT generado desde Azure Function"
    content = $fileContent
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
