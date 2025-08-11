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
$TituloIA = consulta-IA -tipo Titulo -linkFuente 'www'
$IntroIA = consulta-IA -tipo Intro -linkFuente 'www'
$NoticiaIA = consulta-IA -tipo Nota -linkFuente 'www'
$DatosIA = consulta-IA -tipo Datos -linkFuente 'www'
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

    #evita poner imagenes duplicadas
    $urlcache =  $Imagen

### publicidad
###
    Write-Output "Procesando item: $item"

    $counter++

    if ($counter % 3 -eq 0) {
        if ($csvIndex -lt $csvData.Count) {
            $registro = $csvData[$csvIndex]
            Write-Output "Registro del CSV en salto $counter : $($registro | Out-String)"
            $ImgAdsLink = $registro.Imagen
            $LinkAdsLink = $registro.Link
            $TextoAdsLink = $registro.Texto
            $news += "
        <div class='publicidad' style='background-color: white; padding: 10px; border-radius: 5px;'>
          <p><strong>Publicidad</strong></p>
                <a href='$LinkAdsLink' target='_blank'>
                <img src='$ImgAdsLink ' 
                alt='Anuncio Publicitario'  
                style='max-width: 100%; height: auto;'>
             </a>
             <p style='margin-top: 10px; text-align: center;'>
                <a href='$LinkAdsLink' target='_blank'>
                $TextoAdsLink
                </a>
             </p>
          </div>
        
        "
            $csvIndex++
        } else {
            Write-Warning "No hay más registros en el CSV."
        }
    }
}


#$LinksCache | Export-Csv -Path $RutaLinkCache -Encoding UTF8 -NoTypeInformation
$LinkToCsv = $LinksCache | ConvertTo-Csv -NoTypeInformation | Out-String


#####
# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$filevIAcache?ref=$branchsource"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar contenido en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($LinkToCsv))

# Crear body para PUT
$body = @{
    message = "Archivo TXT generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$filevIAcache"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# Respuesta HTTP
$bodyOut = @{
    message = "TXT generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})

####

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
    El uso de este sitio implica la aceptación de nuestros <a href='/terminos'>Términos y Condiciones</a> y nuestra <a href='/privacidad'>Política de Privacidad</a>.
</p>

</body>
</html>
"
$head + ' ' + $news + ' '  + $botom |  Out-File -FilePath "C:\inetpub\wwwroot\index.html" -Encoding utf8 -Force

$indexhtml = $head + ' ' + $news + ' '  + $botom 




# ==== 3. SUBIR TXT A GITHUB (script anterior adaptado) ====
# Obtener SHA si el archivo existe
$uriGet = "https://api.github.com/repos/$owner/$repo/contents/$fileindexhtml?ref=$branch"
try {
    $response = Invoke-RestMethod -Uri $uriGet -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method GET
    $sha = $response.sha
} catch {
    $sha = $null
}

# Codificar contenido en Base64
$contentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($indexhtml))

# Crear body para PUT
$body = @{
    message = "Archivo TXT generado desde Azure Function"
    content = $contentBase64
    branch = $branch
}
if ($sha) { $body.sha = $sha }
$jsonBody = $body | ConvertTo-Json -Depth 10

# Subir archivo
$uriPut = "https://api.github.com/repos/$owner/$repo/contents/$fileindexhtml"
$responsePut = Invoke-RestMethod -Uri $uriPut -Headers @{ Authorization = "token $token"; "User-Agent" = "PowerShell" } -Method PUT -Body $jsonBody

# Respuesta HTTP
$bodyOut = @{
    message = "TXT generado y guardado en GitHub correctamente"
    commitUrl = $responsePut.commit.html_url
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $bodyOut
})


#$head + ' ' + $news + ' '  + $botom |  Out-File -FilePath "C:\syncGITHUB\index.html" -Encoding utf8 -Force
<#
# Ruta de origen
$origen = "C:\inetpub\wwwroot"

# Ruta de destino
$destino = "C:\syncGITHUB"

# Copiar archivos y sobrescribir si existen
Copy-Item -Path "$origen\*" -Destination $destino -Recurse -Force

#### SYNC FILES TO GITHUB

# traemos el token
# Leer el token cifrado
$encryptedTokenDIR = "C:\bats\vIA ONLINE\SecureString\token.txt"
$encryptedToken = Get-Content $encryptedTokenDIR | ConvertTo-SecureString
$plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedToken)
)



# Define las variables
$localRepoPath = "C:\syncGITHUB"
# Construir la URL segura
#$remoteRepoUrl = "https://$plainToken@github.com/davidmdennis/vIAonline.git"
$remoteRepoUrl = "https://$plainToken@github.com/ddennisviaonline/vIAonline-Prod.git"

# Navega al directorio local
Set-Location -Path $localRepoPath

# Inicializa el repositorio Git si no existe
if (-not (Test-Path "$localRepoPath\.git")) {
    git init
}

# Agrega el repositorio remoto (sobrescribe si ya existe)
#git remote remove origin 
git remote remove origin

git remote add origin $remoteRepoUrl
#git remote add origin $remoteRepoUrl

# Agrega todos los archivos al índice
git add .

# Crea un commit
git commit -m "Subida inicial desde PowerShell"

# Sube al repositorio remoto
#git push -u origin master
git pull origin master --rebase

git push -u origin master 
#2>$null

#>