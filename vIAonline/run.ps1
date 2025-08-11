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