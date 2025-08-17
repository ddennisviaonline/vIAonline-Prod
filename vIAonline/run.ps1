# Version 0.8 | MODIFICADO PARA GRABAR EN GITHUB y CLIMA EN MEMORIA
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

Clear
# 1. Carga el HTML desde archivo
#$html = Get-Content -Path ".\archivo.html" -Raw
$URLOrigen = "https://infobae.com"
$response = Invoke-WebRequest -Uri $URLOrigen
$html = $response.Content

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
