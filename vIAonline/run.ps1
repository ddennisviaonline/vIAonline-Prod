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
$token = $env:GitHubToken
##################################################################################################

