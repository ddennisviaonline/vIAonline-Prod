param($Request, $TriggerMetadata)

# ==== CONFIGURACIÓN GITHUB ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$adsPath = "lista.csv"  # csv de publicidades
$vIAcache = "vIAcache.csv" # csv de historico 100 ultimos links
$fileindexhtml = "index.html"
$filevIAcache = "vIAcache.csv"
$txtPath = "archivo.txt"
$branchsource = "main" # powershell
$branch = "master" # webpage
$token = $env:GitHubToken

# ==== 1. DESCARGAR ads.CSV DESDE GITHUB ====
$csvUri = "https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branchsource"

try {
    $response = Invoke-RestMethod -Uri $csvUri -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    # El archivo no existe, no se necesita sha
    $sha = $null
}

$logo = "https://github.com/ddennisviaonline/vIAonline-Prod/blob/master/Imagenes/Logocorto.png?raw=true" # CREAR DNS PARA QUE APUNTE A ESTE LINK

# 1. Carga el HTML desde archivo
#$html = Get-Content -Path ".\archivo.html" -Raw
$URLOrigen = "https://infobae.com"
$response = Invoke-WebRequest -Uri $URLOrigen
$html = $response.Content

# 1. Capturamos cada bloque <a ...>...</a> que contiene la noticia
$patternBloques = '<a\s+href="(?<url>/[^"]+)"[^>]*class="story-card-ctn">.*?<\/a>'

$bloques = [regex]::Matches($html, $patternBloques, [System.Text.RegularExpressions.RegexOptions]::Singleline)

$Articulos = foreach ($bloque in $bloques) {
    $htmlBloque = $bloque.Value

    # Extraemos el título
    $titulo = ([regex]::Match($htmlBloque, '<h2[^>]*>(?<titulo>.*?)<\/h2>', [System.Text.RegularExpressions.RegexOptions]::Singleline)).Groups['titulo'].Value.Trim()
    $titulo = $titulo -replace '\s+', ' '

    # Extraemos el autor
    $autor = ([regex]::Match($htmlBloque, '<b[^>]*class="story-card-author-name"[^>]*>(?<autor>.*?)<\/b>', [System.Text.RegularExpressions.RegexOptions]::Singleline)).Groups['autor'].Value.Trim()

    # URL
    $url = $bloque.Groups['url'].Value.Trim()

    [PSCustomObject]@{
        URL    = $URLOrigen + $url
        Titulo = $titulo
        Autor  = $autor
    }
}

# $Articulos # | Export-Csv -Path "resultados.csv" -NoTypeInformation -Encoding UTF8

#
# Una vez que tenemos los titulos y los url tomamos el url y consultamos a la IA TITULO, INTRO, NOTA y DATOS
#

#función crear titulos por IA

#FUNCIONES

function consulta-IA {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Titulo", "Intro", "Nota", "Datos")]
        [string]$tipo,

        [Parameter(Mandatory)]
        [string]$linkFuente
    )
    switch ($tipo) {
        "Titulo" {
            return "Se consultó el Titulo a la IA"
        }
        "Intro" {
            return "Se consultó la Intro a la IA"
        }
        "Nota" {
            return "Se consultó la Nota a la IA"
        }
        "Datos" {
            return "Se consultó el Datos a la IA"
        }
        default {
            Write-Warning "Acción no reconocida."
        }
    }
    
}

$cache = $null
# Inicializar array vacío
$LinksCache = @()
$CSVcache = @()

# ==== 1. DESCARGAR ads.CSV DESDE GITHUB ====
$csvUri = "https://raw.githubusercontent.com/$owner/$repo/$branchsource/$vIAcache"

try {
    $csvContent = Invoke-RestMethod -Uri $csvUri -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    # El archivo no existe, no se necesita sha
    $sha = $null
}



# si no exite crea file
#if (Test-Path $RutaLinkCache) {
#    $CSVcache = Import-Csv -Path $RutaLinkCache
#    }
<#
if (-not (Test-Path -Path $RutaLinkCache)) {
    $LinksCache += [PSCustomObject]@{ FechayHora = ""; LinkOrigen = ""; TituloOrigen = ""; Titulo = ""; Imagen = ""; Intro = ""; Noticia = ""; Datos = "" }
    $LinksCache | Export-Csv -Path $RutaLinkCache -Encoding UTF8 -NoTypeInformation
} else {
$CSVcache = Import-Csv -Path $RutaLinkCache
}
#>
<#
function IA-Titulo {
    param (
            [string]$linkFuente
        )
    return "Se consultó el titulo a la IA"
}

function IA-Intro {
    param (
            [string]$linkFuente
        )
    return "Se consultó el Intro a la IA"
}

function IA-Nota {
    param (
        [string]$linkFuente
    )
    return "Se consultó la Nota a la IA $linkFuente"
}

function IA-Datos {
    param (
            [string]$linkFuente
        )
    return "Se consultó los Datos a la IA"
}
#>



### una vez que se tienen los titulos se procesan en la IA #####################################################################
<#
function Invoke-OpenAIChatGPT4omini {

    param(
        $question
    )
    
    # Clave y endpoint de Azure OpenAI
    $AZURE_OPENAI_API_KEY = ""
    $AZURE_OPENAI_ENDPOINT = "https://jira-ia.openai.azure.com/"

    # Encabezados, asegurando que el Content-Type tenga charset=utf-8
    $headers = @{
        "api-key" = "$AZURE_OPENAI_API_KEY"
        "Content-Type" = "application/json; charset=utf-8"
        "Accept" = "application/json"
    }

    # ConstrucciÃ³n del mensaje
    $messages = @()
    $messages += @{
        role = 'user'
        content = "$question"
    }

    # Crear el cuerpo de la solicitud en formato JSON
    $body = [ordered]@{
        messages = $messages
    } | ConvertTo-Json -Depth 3

    # Realizar la solicitud POST usando Invoke-WebRequest
    $response = Invoke-WebRequest -Method POST `
        -Uri "$AZURE_OPENAI_ENDPOINT/openai/deployments/gpt-4o-mini/chat/completions?api-version=2025-01-01-preview" `
        -Headers $headers `
        -Body $body `
        -ContentType "application/json; charset=utf-8"

    # Verificar la respuesta para depuraciÃ³n
    if ($response.StatusCode -eq 200) {
        # Asegurarse de que la respuesta estÃ© correctamente decodificada en UTF-8
        $utf8Content = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($response.Content))

        # Procesar la respuesta JSON
        $utf8Content | ConvertFrom-Json | Select-Object -ExpandProperty choices | Select-Object -ExpandProperty message | Select-Object content
    } else {
        Write-Host "Error: $($response.StatusCode) - $($response.StatusDescription)"
    }
}


$Description = @"
Dame la principal Noticia periodistica actual.
Necesito el titulo y una breve discripciÃ³n impactante.
No pidas mÃ¡s detalles ni finalices con recomendaciones adicionales.
"@

$ResultIA = Invoke-OpenAIChatGPT4omini -question $Description 
#>

### Fecha
# toma fecha y la convierte en gmt -3
# Fecha y hora actual en UTC
$utcNow = [datetime]::UtcNow

# Obtener zona horaria GMT-3 (Buenos Aires, Argentina)
$timeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("Argentina Standard Time")

# Convertir la fecha UTC a GMT-3
$fechaGMTLess3 = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcNow, $timeZone)

# Mostrar fecha y hora
$nowGMT3

#
#$fechaGMTLess3 = (Get-Date).ToUniversalTime().AddHours(-3).ToString("dd 'de' MMMM 'de' yyyy", [System.Globalization.CultureInfo]::GetCultureInfo("es-ES"))

### Clima
#Descarga reporte de clima y lo convierte en csv
#Variables
### optimizado para github
<#
try {
    # Configuración GitHub
    $path   = "clima/clima.txt"


    if (-not $token) { throw "GitHubToken no configurado en Application Settings." }

    # Carpeta temporal
    $Dir = Join-Path $env:TEMP "clima"
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null

    # Archivos temporales
    $zipFile = Join-Path $Dir "ClimaArg.zip"

    # Descarga ZIP
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
    $climaResumen = "CABA, $($record.Temperatura)º $primeraPalabra"

    # Prepara contenido para GitHub
    $contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($climaResumen))

    # Consulta SHA si existe
    $uriGet = "https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branchsource"
    try {
        $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
        $sha = $response.sha
    } catch {
        $sha = $null
    }

    # Crea cuerpo para subir archivo
    $body = @{
        message = "Actualización clima desde Azure Function"
        content = $contentBase64
        branch  = $branch
    }
    if ($sha) { $body.sha = $sha }
    $jsonBody = $body | ConvertTo-Json -Depth 10

    # Sube archivo a GitHub
    $uriPut = "https://api.github.com/repos/$owner/$repo/contents/$path"
    $responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

    # Respuesta exitosa
    $clima = @{
        mensaje   = "Archivo clima.txt actualizado en GitHub correctamente"
        clima     = $climaResumen
        commitUrl = $responsePut.commit.html_url
    }

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 200
        Body       = $result | ConvertTo-Json
    })
}
catch {
    $errorMsg = @{
        error   = "Error en Azure Function"
        detalle = $_.Exception.Message
    }
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 500
        Body       = $errorMsg | ConvertTo-Json
    })
}

#>



#$clima
###

<#
$Dir = "C:\inetpub\wwwroot\clima\"
$file = "ClimaArg.zip"
$filePath = $Dir + $file 
$txtfiles = $Dir + "*.txt"
$csvFile =$Dir + "ClimaArg.csv"
$csvHeader =$Dir + "ClimaArgHeaders.csv"
Remove-Item -Path $txtfiles -Force
Invoke-WebRequest -Uri "https://ssl.smn.gob.ar/dpd/zipopendata.php?dato=tiepre" -OutFile $filePath
#Extrae ZIP
Expand-Archive -Path $filePath -DestinationPath $Dir -Force
#pone Headers
Set-Content -Path $csvFile -Value "Ciudad;Fecha;Hora;EstadoDelCielo;Visibilidad;Temperatura;PuntoRocio;Humedad;Viento;Presion" -Encoding UTF8
$fileClima = Get-ChildItem -Path $Dir -Filter *.txt | Select-Object -ExpandProperty Name
$txtfileClima = $Dir + $fileClima
get-Content -Path $txtfileClima | Add-Content -Path $csvFile
$listCima =  Import-Csv $csvFile -Delimiter ';' | Where-Object {$_.PSObject.Properties.Value -match '^Aeroparque'} | Select-Object -First 1
$listCima
$clima = $listCima.EstadoDelCielo
$primeraPalabra = $clima.Split(" ")[0]
$primeraPalabra
$clima = " CABA" + ", " + $listCima.Temperatura + "º " + $primeraPalabra
#>

$head = "
<!DOCTYPE html>
<html lang='es'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>vIA online</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #FEFBF4;
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .encabezado-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .fecha, .clima {
            font-size: 1rem;
            color: #555;
        }
        .noticia {
            background-color: #FEFBF4;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .noticia h2 {
            color: #333;
            font-size: 1.3em;
        }
        .publicidad {
            text-align: center;
            margin: 30px 0;
            padding: 10px;
            background-color: #FEFBF4;
            border: 1px dashed #aaa;
            border-radius: 5px;
        }
        .publicidad img {
            max-width: 100%;
            height: auto;
        }
        .desplegable {
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .flecha {
            font-size: 18px;
            transition: transform 0.3s ease;
            display: inline-block;
        }

        .noticia.abierto .flecha {
            transform: rotate(180deg);
        }
        .noticia .contenido {
            display: none;
            margin-top: 10px;
        }

        .noticia.abierto .contenido {
            display: block;
        }
        .desplegable {
            display: flex;
            justify-content: space-between;
            align-items: center;
            cursor: pointer;
        }
        .flecha {
            font-size: 18px;
            transition: transform 0.3s ease;
            display: inline-block;
        }
        .noticia.abierto .flecha {
            transform: rotate(180deg);
        }


    </style>
</head>
<body>
    <div style='text-align: center;'>
    <img src='$logo' alt='Imagen centrada' style='width: 300px;''>
    </div>

    <div class='encabezado-info'>
        <div class='fecha'>$fechaGMTLess3</div>
        <div class='clima'>Clima:$clima</div>
    </div>
"
