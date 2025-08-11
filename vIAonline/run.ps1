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
    $csvContent = Invoke-RestMethod -Uri $csvUri -Headers @{ "User-Agent" = "PowerShell" }
    # Si quieres procesar el CSV como tabla:
    $links = $csvContent | ConvertFrom-Csv
} catch {
    throw "No se pudo descargar el CSV desde GitHub: $_"
}