param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$csvPath = "lista.csv"               # Ruta del CSV en main
$csvOutputPath = "listaOUTPUT.csv"   # Ruta/nombre del CSV en master
$branchsource = "main"               # Rama origen
$branch = "master"                   # Rama destino
$token = $env:GitHubToken

# ==== 1. DESCARGAR CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchsource/$csvPath"
try {
    $csvContentRaw = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" } -Method GET
    $csvData = $csvContentRaw | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}

# ==== 2. CONVERTIR EL CSV A TEXTO EN MEMORIA ====
$fileContent = ($csvData | ConvertTo-Csv -NoTypeInformation) -join "`n"

if ([string]::IsNullOrWhiteSpace($fileContent)) {
    throw "El contenido CSV está vacío, no se puede subir a GitHub."
}

# ==== 3. ELIMINAR ARCHIVO EXISTENTE SI HAY ====
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    if ($response -and $response.sha) {
        $sha = $response.sha

        # DELETE en la URL sin ?ref
        $uriDelete = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath"
        $deleteBody = @{
            message = "Eliminando archivo antes de sobrescribir desde Azure Function"
            sha     = $sha
            branch  = $branch
        } | ConvertTo-Json -Depth 10 -Compress

        Invoke-RestMethod -Uri $uriDelete -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method DELETE -Body $deleteBody
    }
} catch {
    # Si no existe, se ignora
}

# ==== 4. CODIFICAR A BASE64 ====
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($fileContent))

# ==== 5. SUBIR NUEVO ARCHIVO ====
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$csvOutputPath"
$body = @{
    message = "CSV copiado desde main a master por Azure Function"
    content = $contentBase64
    branch  = $branch
} | ConvertTo-Json -Depth 10 -Compress

$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $body

# ==== 6. RESPUESTA HTTP ====
$bodyOut = @{
    message = "CSV copiado correctamente de main a master (sobrescribiendo archivo si existía)"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})
