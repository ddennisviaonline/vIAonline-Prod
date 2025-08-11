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
$TituloIA = consulta-IA -tipo Titulo -linkFuente 'www'
$TituloIA