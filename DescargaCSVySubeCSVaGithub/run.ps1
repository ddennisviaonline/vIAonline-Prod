param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"         # CSV original en main
$csvOutputPath = "archivo.csv" # CSV que vamos a generar en master
$branchsource = "main"
$branch = "master"
$token = $env:GitHubToken

# ==== 1. DESCARGAR CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchsource/$csvPath"
try {
    $csvContent = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" }
    $csvData = $csvContent | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}

# ==== 2. LÓGICA: Ejemplo agregar columna con fecha ====
$csvData | ForEach-Object { $_ | Add-Member -NotePropertyName "FechaProcesado" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force }

# ==== 3. CONVERTIR A CSV EN MEMORIA ====
$fileContent = $csvData | Export-Csv -NoTypeInformation | Out-String

# ==== 4. SUBIR CSV A GITHUB ====
# Obtener SHA si el archivo ya existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# Crear body para PUT
$body = @{
    message = "Archivo CSV generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# ==== 5. RESPUESTA HTTP ====
$bodyOut = @{
    message = "CSV generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})