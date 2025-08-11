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

param($Request, $TriggerMetadata)

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

$clima
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

#incio HTML
#"El primer diario hecho con IA."
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

####

### Busca imagenes en google
#Solo traigo de la lista los que no tiene autor
#$textos = $Articulos
#$links= get-content -Path C:\inetpub\wwwroot\Publicidad\publicidad.txt

$textossinAutores = $Articulos | Where-Object { [string]::IsNullOrWhiteSpace($_.Autor) } 
$news = @()
$new = @()
$Counter = 0
$linkIndex = 0
#Aca es en donde empezamos a armar los contenidos

# Cargar la lista del CSV
$csvData = $links
# Contador para el foreach
$counter = 0
# Índice para el CSV
$csvIndex = 0

#### compara contra $CSVcache a ver si existe. si no existe busca en la ia si no lo pasa por alto
$ids1 = $textossinAutores.url
$ids2 = $CSVcache.LinkOrigen

$ids1 = $textossinAutores
$ids2 = $CSVcache
# IDs en lista1 que NO están en lista2
$soloEnLista1 = $ids1 | Where-Object { $ids2.LinkOrigen -notcontains $_.url }
$cache = @()
### agrego al csv los nuevos los cuales van a tener campos en blancos
foreach ($registro in $soloEnLista1){
$fechaHora = $nowGMT3 #Get-Date 
$cache += [PSCustomObject]@{ FechayHora = "$fechaHora"; LinkOrigen = $registro.URL; TituloOrigen = $registro.Titulo; Titulo = ""; Imagen = ""; Intro = ""; Noticia = ""; Datos = "" }
}

$TodosLosRegistros = $CSVcache + $cache
# Ordenar por fecha descendente (más reciente primero)
$TodosLosRegistros = $TodosLosRegistros | Sort-Object -Property FechayHora -Descending
# Si hay más de 100 registros, mantener solo los primeros 100
if ($TodosLosRegistros.Count -gt 100) {
    $TodosLosRegistros = $TodosLosRegistros | Select-Object -First 100
}

#troubleshooting
#$LinksCache += [PSCustomObject]@{ FechayHora = "$fechaHora"; LinkOrigen = $LinkOrigen; TituloOrigen = $textos; Titulo = $tituloIA; Imagen = $url; Intro = $introIA; Noticia = $ianews; Datos = $DatosNoticiaIA }
#$LinksCache | Export-Csv -Path $RutaLinkCache -Encoding UTF8 -NoTypeInformation
#$LinksCache =@()
foreach ($noticia in $TodosLosRegistros){