﻿# Version 10 | Cotización dolar, iconos Clima, feriados

# ==============================================
#            AMBIENTE DE PROD
# Cambiar 
param($Timer)
$token = $env:GitHubToken

#Clave y endpoint de Azure OpenAI
$AZURE_OPENAI_API_KEY = $env:AZURE_OPENAI_API_KEY_AzureOpenAI35Turbo                                  
$AZURE_OPENAI_ENDPOINT = $env:AZURE_OPENAI_ENDPOINT_AzureOpenAI35Turbo
# $filePath = "desa/index.html"       # Ruta exacta dentro del repo (case-sensitive)
# ==============================================

# Get-PackageProvider -Name NuGet -ForceBootstrap 
# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# REQUIERE Install-Package HtmlAgilityPack 

################################# variables github ojo con token #################################

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

##################################################################################################
#Clima desde APP
# API Key de WeatherAPI

Clear
# 1. Carga el HTML desde archivo
#$html = Get-Content -Path ".\archivo.html" -Raw
$URLOrigen = "https://infobae.com"
$response = Invoke-WebRequest -Uri $URLOrigen
$html = $response.Content
################################# Publicidad ####################################
# Viaonline
$ViaADS = @"
<div class='publicidad' style='background-color: #FEFBF4; padding: 10px; border-radius: 5px;'>
  <p><strong>Publicidad</strong></p>
        <a href='$LinkAdsLink'>
        <img src='$ImgAdsLink ' 
        alt='Anuncio Publicitario'  
        style='max-width: 80%; height: auto;'>
     </a>
     <p style='margin-top: 10px; text-align: center;'>
        <a href='$LinkAdsLink'>
        $TextoAdsLink
        </a>
     </p>
  </div>
"@

# Google
$googleADS = "<script async src=""https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-1894152981922395""
     crossorigin=""anonymous""></script>
<ins class=""adsbygoogle""
     style=""display:block; text-align:center;""
     data-ad-layout=""in-article""
     data-ad-format=""fluid""
     data-ad-client=""ca-pub-1894152981922395""
     data-ad-slot=""4289209070""></ins>
<script>
     (adsbygoogle = window.adsbygoogle || []).push({});
</script>
"
#################################################################################################


################################# IMPORT AVISOS PUBLICITARIOS####################################
#$links = Import-Csv -Path "C:\bats\vIA ONLINE\ads\ads.csv" #PUBLICIDAD
### reemplazar el import csv on-prem por gitjhub

# ==== 1. DESCARGAR ads.CSV DESDE GITHUB ====
# URL raw del CSV
$csvUrl = "https://raw.githubusercontent.com/ddennisviaonline/vIAonline-Prod/main/vIAonline/ads/ads.csv"


# Importar el CSV directamente
$links = Invoke-WebRequest -Uri $csvUrl | Select-Object -ExpandProperty Content | ConvertFrom-Csv

# Mostrar contenido
$links

##################################################################################################

################################# LOGO PAGINA CREAR VINCULO FUERA DE GITHUB#######################
$logo = "https://viaonline.com.ar/Imagenes/Logocorto.png"

#$logo = "file:///C:\inetpub\wwwroot\Imagenes\Logocorto.png"
#Copy-Item -Path "C:\bats\vIA ONLINE\Imagenes" -Destination "C:\inetpub\wwwroot" -Recurse -Force

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

$Articulos  #| Export-Csv -Path "resultados.csv" -NoTypeInformation -Encoding UTF8

#
# Una vez que tenemos los titulos y los url tomamos el url y consultamos a la IA TITULO, INTRO, NOTA y DATOS
#

#función crear titulos por IA

#FUNCIONES

####
# IA
function Invoke-OpenAIChatGPT4omini {

    param(
        $question
    )
    

    # Encabezados, asegurando que el Content-Type tenga charset=utf-8
    $headers = @{
        "api-key" = "$AZURE_OPENAI_API_KEY"
        "Content-Type" = "application/json; charset=utf-8"
        "Accept" = "application/json"
    }

    # Construcción del mensaje
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
        -Uri "$AZURE_OPENAI_ENDPOINT" `
        -Headers $headers `
        -Body $body `
        -ContentType "application/json; charset=utf-8"

    # Verificar la respuesta para depuración
    if ($response.StatusCode -eq 200) {
        # Asegurarse de que la respuesta esté correctamente decodificada en UTF-8
        $utf8Content = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($response.Content))

        # Procesar la respuesta JSON
        $utf8Content | ConvertFrom-Json | Select-Object -ExpandProperty choices | Select-Object -ExpandProperty message | Select-Object content
    } else {
        Write-Host "Error: $($response.StatusCode) - $($response.StatusDescription)"
    }
}

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
        $DescriptionTitiulo = @"
        Del siguiente link de la noticia: $linkFuente
        Creame el titulo de la Noticia periodistica.
        Necesito que no contenga agregados de " ni *.
        No pidas más detalles ni finalices con recomendaciones adicionales.
"@

        $ResultIAtitle = Invoke-OpenAIChatGPT4omini -question $DescriptionTitiulo
        return $ResultIAtitle.content
            
        }
        "Intro" {
        $DescriptionIntro = @"
        Del siguiente link de la noticia: $linkFuente
        Creame breve introducción de no mas 25 palabras de la Noticia periodistica.
        Necesito que no contenga agregados de " ni *.
        No pidas más detalles ni finalices con recomendaciones adicionales.
"@
        $ResultIAIntro = Invoke-OpenAIChatGPT4omini -question $DescriptionIntro
        return $ResultIAIntro.content
            #return "Se consultó la Intro a la IA"
        }
        "Nota" {
        $DescriptionNota = @"
        Del siguiente link de la noticia: $linkFuente
        Lee la siguiente noticia y redacta un resumen con tus propias palabras. No copies frases textuales ni uses comillas, y conserva solo la información principal y objetiva. Mantén un estilo periodístico claro y conciso.
        Necesito que no contenga agregados de " ni *.
        No pidas más detalles ni finalices con recomendaciones adicionales.
        No devuelvas un mensaje consultando si podes ayudarnos con algo mas.
        Si no logras resolver la noticias no comentes nada.
"@
        $ResultIANota = Invoke-OpenAIChatGPT4omini -question $DescriptionNota
        return $ResultIANota.content
        }
        "Datos" {
        $DescriptionDatos = @"
        Del siguiente link de la noticia: $linkFuente
        Extrae únicamente los datos esenciales de la noticia. 
        No agregues explicaciones, conclusiones, ni texto adicional. 
        Devuélvelos en formato JSON como una lista ordenada, sin usar nombres de claves.
        El orden de los elementos debe ser: título, lugar, hechos.
        No escribas nada fuera del JSON.
"@
        $ResultIADatos = Invoke-OpenAIChatGPT4omini -question $DescriptionDatos
        return $ResultIADatos.content
        }
        default {
            Write-Warning "Acción no reconocida."
        }
    }
    
}

# Crea csv el cual va a guardar el historico de los ultmos 100 links el resto deberia estar en los index.html publicados como historicos

# Ruta del archivo
$cache = $null
$LinksCache = @()
$CSVcache = @()
####################################################### IMPORT viacache.csv #######################################################
<#
$RutaLinkCache = "C:\bats\vIA ONLINE\vIAcache.csv"
# Inicializar array vacío
# si no exite crea file
if (Test-Path $RutaLinkCache) {
    $CSVcache = Import-Csv -Path $RutaLinkCache
    }
#>

#### importa el csv de github
# URL del archivo en GitHub
$csvUrl = "https://raw.githubusercontent.com/ddennisviaonline/vIAonline-Prod/main/vIAonline/temp/vIAcache.csv"
$CSVcache = Invoke-WebRequest -Uri $csvUrl | Select-Object -ExpandProperty Content | ConvertFrom-Csv
    # Mostrar contenido
$CSVcache    
    #$RutaLinkCache


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
    $AZURE_OPENAI_API_KEY = "EiRXnyR7YDMlHPWv88Vs3aDKz6OSAi7yvtnixpM2ILwzRjnxx5QZJQQJ99BFACYeBjFXJ3w3AAABACOGVyZ1"
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
$fechaGMTLess3 = (Get-Date).ToUniversalTime().AddHours(-3).ToString("dd 'de' MMMM 'de' yyyy", [System.Globalization.CultureInfo]::GetCultureInfo("es-ES"))
$fechaActual = "📆" + ' ' + $fechaGMTLess3
### Clima
#### DESDE ACA EXTRAER ZIP EN MEMORIA

<#
Add-Type -AssemblyName System.IO.Compression

# URL del ZIP
$url = "https://ssl.smn.gob.ar/dpd/zipopendata.php?dato=tiepre"

# Descargar ZIP en memoria
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$bytes = $response.Content

# Cargar ZIP en memoria
$memStream = New-Object System.IO.MemoryStream(,$bytes)
$zip = New-Object System.IO.Compression.ZipArchive($memStream)

# Buscar el TXT dentro del ZIP
$txtEntry = $zip.Entries | Where-Object { $_.FullName -like "*.txt" }

if ($txtEntry) {
    $reader = New-Object System.IO.StreamReader($txtEntry.Open())
    $txtContent = $reader.ReadToEnd()
    $reader.Close()

    # Definir encabezados personalizados
    $headers = "Ciudad","Fecha","Hora","EstadoDelCielo","Visibilidad","Temperatura","PuntoRocio","Humedad","Viento","Presion"

    # Convertir TXT a CSV usando encabezados y delimitador ;
    $listCima = $txtContent | ConvertFrom-Csv -Delimiter ";" -Header $headers

    # Mostrar datos
  $listCima = $listCima | Where-Object { $_.Ciudad -match '^Aeroparque' } | Select-Object -First 1
}
$listCima
$clima = $listCima.EstadoDelCielo
$primeraPalabra = $clima.Split(" ")[0]
$primeraPalabra
$clima = " CABA" + ", " + $listCima.Temperatura + "º " + $primeraPalabra
# Liberar recursos
$zip.Dispose()
$memStream.Dispose()
#>


#$tokenClima
$apiKey = $env:tokenClima
# Ciudad de la que deseas obtener el clima
$ciudad = "Buenos Aires"

# URL de la API
$url = "http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$ciudad&lang=es"

# Petición HTTP y parseo de la respuesta JSON
$response = Invoke-RestMethod -Uri $url -Method Get

# Mostrar resultados
Write-Host "Ciudad: $($response.location.name), $($response.location.country)"
Write-Host "Temperatura: $($response.current.temp_c) °C"
Write-Host "Sensación térmica: $($response.current.feelslike_c) °C"
Write-Host "Condición: $($response.current.condition.text)"
Write-Host "Última actualización: $($response.current.last_updated)"

$clima = " CABA" + ", " + $($response.current.temp_c) + "º " + $($response.current.condition.text)
<#
#####
$apiKey = $env:WeatherAPI
# Ciudad de la que deseas obtener el clima
$ciudad = "Buenos Aires"

# URL de la API
$url = "http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$ciudad&lang=es"

# Petición HTTP y parseo de la respuesta JSON
$response = Invoke-RestMethod -Uri $url -Method Get

$condicionClimatica = $($response.current.condition.text)

# Asignamos el ícono según la condición
if ($condicionClimatica -eq "Despejado") {
    $IconCondicion = "☀️"
}
elseif ($condicionClimatica -eq "Algo nublado" -or $condicionClimatica -eq "Parcialmente nublado") {
    $IconCondicion = "🌤️"
}
elseif ($condicionClimatica -eq "Nublado") {
    $IconCondicion = "☁️"
}
elseif ($condicionClimatica -eq "Lluvias aisladas" -or $condicionClimatica -eq "Lluvia ligera") {
    $IconCondicion = "🌦️"
}
elseif ($condicionClimatica -eq "Lluvia moderada") {
    $IconCondicion = "🌧️"
}
elseif ($condicionClimatica -eq "Lluvia fuerte" -or $condicionClimatica -eq "Tormenta intensa") {
    $IconCondicion = "⛈️"
}
elseif ($condicionClimatica -eq "Tormenta severa" -or $condicionClimatica -eq "Granizo") {
    $IconCondicion = "🌩️"
}
elseif ($condicionClimatica -eq "Nieve") {
    $IconCondicion = "❄️"
}
elseif ($condicionClimatica -eq "Niebla" -or $condicionClimatica -eq "Neblina") {
    $IconCondicion = "🌫️"
}
elseif ($condicionClimatica -eq "Ventoso" -or $condicionClimatica -eq "Viento fuerte") {
    $IconCondicion = "🌬️"
}
else {
    $IconCondicion = "❓"  # Por si no coincide con ninguna condición
}

# Mostrar resultados
Write-Host "Ciudad: $($response.location.name), $($response.location.country)"
Write-Host "Temperatura: $($response.current.temp_c) °C"
Write-Host "Sensación térmica: $($response.current.feelslike_c) °C"
Write-Host "Condición: $($response.current.condition.text)"
Write-Host "Última actualización: $($response.current.last_updated)"

$clima = " CABA" + ", " + $($response.current.temp_c) + "º " + $IconCondicion + ' ' + $($response.current.condition.text)

#>
#### HASTA ACA EXTRAER ZIP EN MEMORIA
<#
#Descarga reporte de clima y lo convierte en csv
#Variables
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

# URL de la API
$url = "https://dolarapi.com/v1/dolares"

try {
    # Obtener datos en formato JSON
    $response = Invoke-RestMethod -Uri $url -Method Get

}
catch {
    Write-Host "Error al obtener la cotización: $_"
}
    
    # Mostrar todos los tipos de dólar
    $response | Select-Object nombre, compra, venta
    
    
    $dolaroficial = $response | Where-Object { $_.casa -eq "oficial" }
    $oficial = "💵 Dólar oficial - Compra: $($dolaroficial.compra) | Venta: $($dolaroficial.venta)"
    
    $dolarBlue = $response | Where-Object { $_.casa -eq "blue" }
    $blue = "💵 Dólar Blue - Compra: $($dolarBlue.compra) | Venta: $($dolarBlue.venta)"

### Obtengo fecha de feriado
# Definir el año
$anio = (Get-Date).Year

# URL de la API de feriados
$Url = "https://www.argentina.gob.ar/interior/feriados-nacionales-$anio"
  try {
        $pagina = Invoke-WebRequest -Uri $Url -UseBasicParsing
    } catch {
    Write-Host "Ocurrió un error al acceder a la URL: $_"
}

# Si $pagina.Content es un string con saltos de línea
$array = $pagina.Content -split "`r?`n"

# Ahora sí $array es un array donde cada elemento es una línea
$lineas476a479 = $array[393..424]
$lineas476a479
function Clasificar-Feriados {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$lineasFeriados
    )

    # 1️⃣ Unir líneas en un JSON válido
    $jsonText = "[" + ($lineasFeriados -join "`n") + "]"

    # 2️⃣ Quitar la coma final sobrante si existe
    $jsonText = $jsonText -replace ",\s*\]$", "]"

    # 3️⃣ Convertir a objetos PowerShell
    try {
        $feriados = $jsonText | ConvertFrom-Json
    } catch {
        Write-Error "Error al convertir JSON. Revisa el formato de las líneas."
        return
    }

    # 4️⃣ Clasificar por tipo de etiqueta
    $feriadosB = $feriados | Where-Object { $_.label -match "\(b\)" }
    $feriadosC = $feriados | Where-Object { $_.label -match "\(c\)" }
    $feriadosSinBC = $feriados | Where-Object { $_.label -notmatch "\(b\)|\(c\)" }

    # 5️⃣ Devolver las variables como un objeto para fácil acceso
    return [PSCustomObject]@{
        B = $feriadosB
        C = $feriadosC
        SinBC = $feriadosSinBC
    }
}

# -----------------------------
# Ejemplo de uso con tu variable
$resultado = Clasificar-Feriados -lineasFeriados $lineas476a479

# Mostrar los feriados que no son (b) ni (c)
$resultado.SinBC | ForEach-Object {
    "$($_.date) - $($_.label) - $($_.type)"
}
$feriados = $resultado.SinBC
# Si querés también podés acceder a los que son (b) o (c):
# $resultado.B
# $resultado.C
# Fecha actual
$hoy = Get-Date

# Filtrar feriados que sean posteriores a hoy y ordenar por fecha
$proximoFeriadoSinBC = $resultado.SinBC |
    Where-Object { [datetime]::Parse($_.date) -ge $hoy } |
    Sort-Object { [datetime]::Parse($_.date) } |
    Select-Object -First 1

# Mostrar resultado
if ($proximoFeriadoSinBC) {
    Write-Output "Próximo feriado (sin (b) ni (c)): $($proximoFeriadoSinBC.label) - Fecha: $($proximoFeriadoSinBC.date)"
} else {
    Write-Output "No hay próximos feriados sin (b) ni (c) en la lista."
}
$fecha = $proximoFeriadoSinBC.date 

# Convertir a tipo DateTime
$fechaDateTime = [datetime]::ParseExact($fecha, "dd/MM/yyyy", $null)

# Formatear en español
$fechaFormateada = $fechaDateTime.ToString("dddd dd 'de' MMMM 'de' yyyy", [System.Globalization.CultureInfo]::GetCultureInfo("es-ES"))

$fechaFormateada

 $ProximoFeriado = "📆 Próximo feriado: " + $proximoFeriadoSinBC.label + ' ' + $fechaFormateada
###

$head = "
<!DOCTYPE html>
<html lang='es'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>vIA online</title>
    <link rel='icon' type='image/png' sizes='512x512' href='https://viaonline.com.ar/Imagenes/favicon.ico'>
      <!-- Script global de AdSense (va una sola vez en toda la web) -->
    <meta name='google-adsense-account' content='ca-pub-1894152981922395'>
    <style>
/* Contenedor principal de noticias */

.contenedor-noticias {
    display: grid;
    grid-template-columns: repeat(4, 1fr); /* 4 columnas en PC */
    gap: 20px;
    margin: 20px;
}

    body {
        background-color: #FEFBF4;
        font-family: Arial, sans-serif;
        margin: 0;
        padding: 20px;
    }

    /* Logo centrado */
    .logo {
        text-align: center;
        margin-bottom: 10px;
    }

    .logo img {
        width: 400px;
    }

/* Cada noticia */
.noticia {
    border: 1px solid #ccc;
    border-radius: 8px;
    padding: 10px;
    cursor: pointer;
    background-color: #FEFBF4;
    transition: box-shadow 0.3s;
}

.noticia:hover {
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
}

.noticia h1, .noticia h2 {
    margin: 0 0 10px 0;
    font-size: 16px;
    text-align: center;
}

.noticia img {
    width: 100%;
    display: block;
    margin-bottom: 10px;
}

/* Desplegable contenido */
.contenido {
    display: none;
    margin-top: 10px;
    font-size: 14px;
    line-height: 1.4;
}

.noticia.abierto .contenido {
    display: block;
}

/* Fila de publicidad */
.publicidad {
    grid-column: 1 / -1; /* ocupa todo el ancho */
    text-align: center;
    padding: 20px;
    background-color: #f0f0f0;
    font-weight: bold;
    border-radius: 8px;
}

/* Contenedor fecha y clima */
.encabezado-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
    padding: 0 10px;
}

/* Adaptación a celulares */
@media (max-width: 768px) {
    .contenedor-noticias {
        grid-template-columns: 1fr; /* una columna */
    }
}
    </style>
</head>
<body>

    <!-- Logo -->
    <div class='logo'>
        <a href='https://viaonline.com.ar/'>
            <img src='https://viaonline.com.ar/Imagenes/Logocorto.png' alt='Imagen centrada'>
        </a>
    </div>

    <!-- Fecha y clima -->
    <div class='encabezado-info'>
        <div class='fecha'>$fechaActual</div>
        <div class='clima'>Clima:$clima</div>
        <div class='clima'>$oficial</div>
        <div class='clima'>$blue</div>
        <div class='clima'>$ProximoFeriado</div>        
    </div>
<div class='contenedor-noticias'>
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
$fechaHora = Get-Date 
$cache += [PSCustomObject]@{ FechayHora = "$fechaHora"; LinkOrigen = $registro.URL; TituloOrigen = $registro.Titulo; Titulo = ""; Imagen = ""; Intro = ""; Noticia = ""; Datos = "" }
}

$TodosLosRegistros = $CSVcache + $cache
# Ordenar por fecha descendente (más reciente primero)
$TodosLosRegistros = $TodosLosRegistros | Sort-Object -Property FechayHora -Descending
# Si hay más de 100 registros, mantener solo los primeros 100
if ($TodosLosRegistros.Count -gt 100) {
    $TodosLosRegistros = $TodosLosRegistros | Select-Object -First 100 #### CANTIDAD DE RETGISTROS A MOSTRAR
}

#troubleshooting
#$LinksCache += [PSCustomObject]@{ FechayHora = "$fechaHora"; LinkOrigen = $LinkOrigen; TituloOrigen = $textos; Titulo = $tituloIA; Imagen = $url; Intro = $introIA; Noticia = $ianews; Datos = $DatosNoticiaIA }
#$LinksCache | Export-Csv -Path $RutaLinkCache -Encoding UTF8 -NoTypeInformation
#$LinksCache =@()
#alterna publicidad con el contador
$adscnt = 0
foreach ($noticia in $TodosLosRegistros){
$LinkOrigen = $noticia.LinkOrigen #$URLOrigen + $noticia.URL
$textos = $noticia.TituloOrigen
#$links= get-content -Path C:\inetpub\wwwroot\Publicidad\publicidad.txt

#### si está incompleto consulto en la ia y en google
####
$incompletos = $noticia  | Where-Object {
    -not $_.Titulo  -and
    -not $_.Imagen  -and
    -not $_.Intro   -and
    -not $_.Noticia -and
    -not $_.Datos
}

if (!$incompletos) {
    Write-Host "✅ Hay registros completos."
    # Aquí puedes hacer algo con $completos
    $FechayHora = $noticia.FechayHora
    $LinkOrigen = $noticia.LinkOrigen   
    $TituloOrigen = $noticia.TituloOrigen
    $TituloIA = $noticia.Titulo
    $Imagen = $noticia.Imagen   
    $IntroIA = $noticia.Intro    
    $NoticiaIA = $noticia.Noticia      
    $DatosIA = $noticia.Datos 
} else {
    Write-Host "❌ No hay registros completos."

####
$TituloIA = consulta-IA -tipo Titulo -linkFuente $LinkOrigen
$IntroIA = consulta-IA -tipo Intro -linkFuente $LinkOrigen
$NoticiaIA = consulta-IA -tipo Nota -linkFuente $LinkOrigen
#$DatosIA = consulta-IA -tipo Datos -linkFuente $LinkOrigen
# Resultado final




    $new =  $tituloIA #$noticia.Titulo
    $query = $textos # titulo para que google me traiga la imagen
    $Imagen = "https://www.google.com/search?q={0}&tbm=isch" -f ($query -replace " ", "+")

    try {
    # Realiza la solicitud web
    $response = Invoke-WebRequest -Uri $Imagen
    $array  = $response.Images.outerHTML

    } catch {
    Write-Host "Error al realizar la solicitud web: $($_.Exception.Message)"
}

    $linea2 = $array[2]
    
    
    if ($linea2 -match 'src="(https://encrypted-tbn0\.gstatic\.com[^"]+)"') {
    $Imagen = $matches[1]
    if ($Imagen -eq $urlcache ) {$Imagen= $matches[3]
    Write-Host "es igual" -ForegroundColor Cyan
    Write-Host $linea2 -ForegroundColor Cyan
    Write-Host $urlcache -ForegroundColor Cyan
    }
    #Write-Output $url
}
}
$fechaHora = Get-Date 
#Agrego datos al csv !!!!! despues hay que corregirlo para que solo agregue los que no existan
$LinksCache += [PSCustomObject]@{ FechayHora = "$fechaHora"; LinkOrigen = $LinkOrigen; TituloOrigen = $textos; Titulo = $TituloIA; Imagen = $Imagen; Intro = $NoticiaIA; Noticia = $NoticiaIA; Datos = $DatosIA }




$news += "
		<div class='noticia' onclick='this.classList.toggle(""abierto"")'>
			<h1>$TituloIA</h1>
			<img src='$Imagen' alt='Imagen noticia 1'>
			<div class=""desplegable""><h2>$introIA ▼</h2></div>
			<div class=""contenido"">
				<p>$NoticiaIA</p>
			</div>
		</div>
"


<#
$news += "
    <div class='noticia' onclick='this.classList.toggle('abierto')'>
        <h1>$TituloIA</h1>
        <img src='$Imagen' alt='Imagen noticia'>
        <div class='desplegable'><h2>$introIA ▼</h2></div>
        <div class='contenido'>
            <p>$NoticiaIA</p>
        </div>
    </div>
"
#>
<#
$news += "
<div class='noticia' onclick='this.classList.toggle(""abierto"")'>
    <h1 style='margin: 0; text-align: center;'>$TituloIA</h1> 
    <img src='$Imagen' 
         alt='Imagen centrada' 
         style='display: block; margin: auto; width: 40%;'>

    <div class='desplegable'>
        <h2 style='margin: 0;'>$introIA</h2>  
        <span class='flecha'>▼</span>
    </div>

    <div class='contenido'>
        <p>$NoticiaIA<br></p>
        <p>$DatosIA</p>
    </div>
</div>
"
#>
    #evita poner imagenes duplicadas
    $urlcache =  $Imagen

### publicidad
###
    Write-Output "Procesando item: $item"

    $counter++

    if ($counter % 8 -eq 0) {
        if ($csvIndex -lt $csvData.Count) {
            $registro = $csvData[$csvIndex]
            Write-Output "Registro del CSV en salto $counter : $($registro | Out-String)"
            $ImgAdsLink = $registro.Imagen
            $LinkAdsLink = $registro.Link
            $TextoAdsLink = $registro.Texto
            $news += $ViaADS
            <#
             "
        <div class='publicidad' style='background-color: #FEFBF4; padding: 10px; border-radius: 5px;'>
          <p><strong>Publicidad</strong></p>
                <a href='$LinkAdsLink'>
                <img src='$ImgAdsLink ' 
                alt='Anuncio Publicitario'  
                style='max-width: 80%; height: auto;'>
             </a>
             <p style='margin-top: 10px; text-align: center;'>
                <a href='$LinkAdsLink'>
                $TextoAdsLink
                </a>
             </p>
          </div>
        
        "
        #>
            $csvIndex++
        } else {
            Write-Warning "No hay más registros en el CSV."
        }
    }
}
$news += $googleADS
$news += "</div>"
################################# EXPORTA LOS REGISTROS DE NOTICIAS A GITHUB #################################
################################# ELIMINA REGISTRO VIEJO Y EXPORTA EL NUEVO ##################################
$LinksCache # | Export-Csv -Path $RutaLinkCache -Encoding UTF8 -NoTypeInformation

### desde aca borra el file vIAcache.csv
# ==== CONFIGURACIÓN ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$filePath = "vIAonline/temp/vIAcache.csv"       # Ruta exacta dentro del repo (case-sensitive)
$branch = "main"              # Rama donde está el archivo

# ==== 1. Obtener el SHA del archivo ====
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}
$urlpath = $filePath + "?ref=" + $branch
$shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$response = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method Get
$fileSha = $response.sha

# ==== 2. Eliminar el archivo ====
$body = @{
    message = "Eliminar archivo $filePath"
    sha     = $fileSha
    branch  = $branch
} | ConvertTo-Json

$deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete -Body $body

Write-Host "Archivo eliminado: $filePath en rama $branch"
### hasta aca borra el file vIAcache.csv
### desde aca crea el file vIAcache.csv
# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$urlpath = $filePath + "?ref=" + $branch
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"

try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Convertir el objeto a CSV en memoria (string)
$csvString = $LinksCache | ConvertTo-Csv -NoTypeInformation

# Convertir ese string a Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($csvString -join "`n"))

# Mostrar resultado
$contentBase64

# Crear body para PUT
$body = @{
    message = "Archivo TXT generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody
# Respuesta HTTP
$bodyOut = @{
    message = "TXT generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json
$bodyOut
### hasta aca crea el file vIAcache.csv

# Mostrar resultado
$news

####




$botom = @()
$botom +="
<p style='font-size: 12px; color: #666; text-align: center;'>
    © 2025 VIA ONLINE. Todos los derechos reservados.  
    Queda prohibida la reproducción total o parcial de los contenidos de este sitio sin autorización previa y por escrito.  
    Las marcas, logotipos y contenidos pertenecen a sus respectivos propietarios.  
    Este sitio web puede contener enlaces a sitios externos sobre los cuales VIA ONLINE no tiene responsabilidad alguna.  
    El uso de este sitio implica la aceptación de nuestros <a href='https://viaonline.com.ar/TerminosyCondiciones.html'>Términos y Condiciones</a> y nuestra <a href='https://viaonline.com.ar/privacidad.html'>Política de Privacidad</a>.
</p>

</body>
</html>
"

######################################## eliminar el archivo index y subir el nuevo############################
#$head + ' ' + $news + ' '  + $botom |  Out-File -FilePath "C:\inetpub\wwwroot\index.html" -Encoding utf8 -Force

$indexfile = $head + ' ' + $news + ' '  + $botom 

Write-Host $indexfile -ForegroundColor Cyan

### desde aca borra el file vIAcache.csv
# ==== CONFIGURACIÓN ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$filePath = "index.html"       # Ruta exacta dentro del repo (case-sensitive)
$branch = "master"              # Rama donde está el archivo

# ==== 1. Obtener el SHA del archivo ====
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}
$urlpath = $filePath + "?ref=" + $branch
$shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$response = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method Get
$fileSha = $response.sha

# ==== 2. Eliminar el archivo ====
$body = @{
    message = "Eliminar archivo $filePath"
    sha     = $fileSha
    branch  = $branch
} | ConvertTo-Json

$deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete -Body $body

Write-Host "Archivo eliminado: $filePath en rama $branch"
### hasta aca borra el file vIAcache.csv
### desde aca crea el file vIAcache.csv
# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$urlpath = $filePath + "?ref=" + $branch
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"

try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Convertir el objeto a CSV en memoria (string)
#$csvString = $LinksCache | ConvertTo-Csv -NoTypeInformation

# Convertir ese string a Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($indexfile -join "`n"))

# Mostrar resultado
$contentBase64

# Crear body para PUT
$body = @{
    message = "Archivo $filePath generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody
# Respuesta HTTP
$bodyOut = @{
    message = "$filePath generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json
$bodyOut
### hasta aca crea el file vIAcache.csv


### Crea terminos y condiciones DESDE ACA
######################################## eliminar el archivo index y subir el nuevo############################
#$head + ' ' + $news + ' '  + $botom |  Out-File -FilePath "C:\inetpub\wwwroot\index.html" -Encoding utf8 -Force
$terminos = "<h2>Términos y Condiciones</h2>
<p>Última actualización: 5 de agosto de 2025</p>

<p>Bienvenido a VIA ONLINE. Al acceder y utilizar nuestro sitio web (https://www.viaonline.com.ar), aceptás cumplir con los siguientes Términos y Condiciones. Si no estás de acuerdo con alguno de ellos, te pedimos que no utilices el sitio.</p>

<h3>1. Uso del sitio</h3>
<p>El contenido de VIA ONLINE es solo para uso informativo. No garantizamos que la información sea completa, precisa o actualizada. El uso de los contenidos queda bajo responsabilidad del usuario.</p>

<h3>2. Propiedad intelectual</h3>
<p>Todos los contenidos publicados (textos, imágenes, logos, videos, etc.) son propiedad de VIA ONLINE o de terceros que han autorizado su uso. Está prohibida su reproducción total o parcial sin autorización previa y por escrito.</p>

<h3>3. Enlaces a terceros</h3>
<p>El sitio puede contener enlaces a páginas externas. VIA ONLINE no se hace responsable por el contenido, políticas o prácticas de esos sitios.</p>

<h3>4. Modificaciones</h3>
<p>Nos reservamos el derecho de modificar estos Términos y Condiciones en cualquier momento. Las modificaciones entrarán en vigencia desde su publicación en el sitio.</p>

<h3>5. Jurisdicción</h3>
<p>Estos términos se rigen por las leyes de la República Argentina. Cualquier conflicto será sometido a los tribunales competentes de la Ciudad Autónoma de Buenos Aires.</p>
"
$indexfile = $head + ' ' + $terminos + ' '  + $botom

### desde aca borra el file vIAcache.csv
# ==== CONFIGURACIÓN ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$filePath = "TerminosyCondiciones.html"       # Ruta exacta dentro del repo (case-sensitive)
$branch = "master"              # Rama donde está el archivo

# ==== 1. Obtener el SHA del archivo ====
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}
$urlpath = $filePath + "?ref=" + $branch
$shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$response = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method Get
$fileSha = $response.sha

# ==== 2. Eliminar el archivo ====
$body = @{
    message = "Eliminar archivo $filePath"
    sha     = $fileSha
    branch  = $branch
} | ConvertTo-Json

$deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete -Body $body

Write-Host "Archivo eliminado: $filePath en rama $branch"
### hasta aca borra el file vIAcache.csv
### desde aca crea el file vIAcache.csv
# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$urlpath = $filePath + "?ref=" + $branch
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"

try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Convertir el objeto a CSV en memoria (string)
#$csvString = $LinksCache | ConvertTo-Csv -NoTypeInformation

# Convertir ese string a Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($indexfile -join "`n"))

# Mostrar resultado
$contentBase64

# Crear body para PUT
$body = @{
    message = "Archivo $filePath generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody
# Respuesta HTTP
$bodyOut = @{
    message = "$filePath generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json
### Crea terminos y condiciones HASTA ACA
### Crea privacidad DESDE ACA
######################################## eliminar el archivo index y subir el nuevo############################
$privacidad = "<h2>Política de Privacidad</h2>
<p>Última actualización: 5 de agosto de 2025</p>

<p>En VIA ONLINE respetamos tu privacidad y queremos que entiendas cómo recopilamos, usamos y protegemos tu información.</p>

<h3>1. Información que recopilamos</h3>
<p>No recopilamos datos personales de forma automática. Sin embargo, al usar formularios de contacto, comentarios o suscripciones, podemos solicitarte nombre, correo electrónico u otra información de contacto.</p>

<h3>2. Uso de la información</h3>
<p>Usamos la información proporcionada por los usuarios para responder consultas, mejorar el sitio y enviar comunicaciones, siempre que el usuario haya dado su consentimiento.</p>

<h3>3. Cookies</h3>
<p>Este sitio puede utilizar cookies para mejorar la experiencia de navegación. Podés configurar tu navegador para bloquearlas si lo preferís.</p>

<h3>4. Compartir información</h3>
<p>No compartimos información personal con terceros, salvo obligación legal o consentimiento explícito del usuario.</p>

<h3>5. Seguridad</h3>
<p>Tomamos medidas razonables para proteger tu información, pero ningún sistema es 100% seguro.</p>

<h3>6. Derechos del usuario</h3>
<p>Podés solicitar el acceso, rectificación o eliminación de tus datos enviándonos un correo a contacto@viaonline.com.</p>

<h3>7. Cambios en esta política</h3>
<p>Nos reservamos el derecho a modificar esta política en cualquier momento. Las modificaciones se publicarán en esta misma página.</p>

"
$indexfile = $head + ' ' + $privacidad + ' '  + $botom

### desde aca borra el file
# ==== CONFIGURACIÓN ====
$owner = "ddennisviaonline"
$repo = "vIAonline-Prod"
$filePath = "privacidad.html"       # Ruta exacta dentro del repo (case-sensitive)
$branch = "master"              # Rama donde está el archivo

# ==== 1. Obtener el SHA del archivo ====
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}
$urlpath = $filePath + "?ref=" + $branch
$shaUrl = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$response = Invoke-RestMethod -Uri $shaUrl -Headers $headers -Method Get
$fileSha = $response.sha

# ==== 2. Eliminar el archivo ====
$body = @{
    message = "Eliminar archivo $filePath"
    sha     = $fileSha
    branch  = $branch
} | ConvertTo-Json

$deleteUrl = "https://api.github.com/repos/$owner/$repo/contents/$filePath"
Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Delete -Body $body

Write-Host "Archivo eliminado: $filePath en rama $branch"
### hasta aca borra el file 
### desde aca crea el file 
# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$urlpath = $filePath + "?ref=" + $branch
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"

try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Convertir el objeto a CSV en memoria (string)
#$csvString = $LinksCache | ConvertTo-Csv -NoTypeInformation

# Convertir ese string a Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($indexfile -join "`n"))

# Mostrar resultado
$contentBase64

# Crear body para PUT
$body = @{
    message = "Archivo $filePath generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$urlpath"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody
# Respuesta HTTP
$bodyOut = @{
    message = "$filePath generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json
### Crea privacidad ACA

