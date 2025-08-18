param($Request, $TriggerMetadata)
function Get-Clima {
    try {
        Write-Output "=== Descargando ZIP del SMN ==="
        $url = "https://ssl.smn.gob.ar/dpd/zipopendata.php?dato=tiepre"

        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15

        if (-not $resp) {
            throw "La respuesta del SMN fue nula."
        }

        Write-Output "StatusCode: $($resp.StatusCode)"
        Write-Output "ContentLength: $($resp.RawContentLength)"
        Write-Output "Content-Type: $($resp.Headers.'Content-Type')"

        if ($resp.Headers.'Content-Type' -notmatch "zip") {
            throw "El servidor devolvió algo que no parece ZIP (posiblemente HTML de error)."
        }

        $bytes = $resp.Content
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms)

        $txtEntry = $zip.Entries | Where-Object { $_.FullName -like "*.txt" } | Select-Object -First 1
        if (-not $txtEntry) {
            throw "No se encontró ningún archivo TXT dentro del ZIP."
        }

        $reader = New-Object System.IO.StreamReader($txtEntry.Open(), [System.Text.Encoding]::GetEncoding("iso-8859-1"))
        $txtContent = $reader.ReadToEnd()
        $reader.Close()

        $headers = "Ciudad","Fecha","Hora","EstadoDelCielo","Visibilidad","Temperatura","PuntoRocio","Humedad","Viento","Presion"
        $listCima = $txtContent | ConvertFrom-Csv -Delimiter ";" -Header $headers

        $aeroparque = $listCima | Where-Object { $_.Ciudad -match '^Aeroparque' } | Select-Object -First 1
        if (-not $aeroparque) {
            throw "No se encontró la estación Aeroparque en el TXT."
        }

        $primeraPalabra = $aeroparque.EstadoDelCielo.Split(" ")[0]
        $clima = "CABA, $($aeroparque.Temperatura)º $primeraPalabra"

        $zip.Dispose()
        $ms.Dispose()

        return $clima
    }
    catch {
        Write-Error "Error en Get-Clima: $_"
        return "Error clima"
    }
}

# Ejecución
$clima = Get-Clima
Write-Output "Resultado clima: $clima"
