param(
    [Parameter(Mandatory = $true)]
    [string]$ExportDirectory,

    [Parameter(Mandatory = $true)]
    [string]$ProjectDirectory
)


$htmlFiles = @(Get-ChildItem -LiteralPath $ExportDirectory -Filter '*.html' |
    Where-Object { $_.Name -notlike '*.offline.html' })
if ($htmlFiles.Count -eq 0) {
    throw "No se encontró el HTML exportado en $ExportDirectory"
}

$style = @'

/* Pantalla visible antes de que arranque el runtime de Godot. */
body {
    background: #02070b url('loading-backdrop.png') center center / cover no-repeat fixed;
}

#status {
    visibility: visible;
    background:
        linear-gradient(180deg, rgba(1, 8, 14, 0.76), rgba(1, 5, 9, 0.88)),
        url('loading-backdrop.png') center center / cover no-repeat;
}

#status-brand {
    color: #dff8ff;
    font-family: Arial, sans-serif;
    font-size: clamp(1.5rem, 4vw, 3.6rem);
    font-weight: 700;
    letter-spacing: 0.08em;
    margin-bottom: 2rem;
    text-align: center;
    text-shadow: 0 0 18px rgba(48, 210, 255, 0.85), 0 3px 12px #000;
}

#status-progress {
    accent-color: #22c7ff;
    filter: drop-shadow(0 0 8px rgba(34, 199, 255, 0.72));
    height: 0.55rem;
}
'@

foreach ($html in $htmlFiles) {
    $htmlText = Get-Content -LiteralPath $html.FullName -Raw
    if ($htmlText -notmatch 'id="status-brand"') {
        $htmlText = $htmlText.Replace('<progress id="status-progress"></progress>', '<div id="status-brand">NOCHE DE LOS INFECTADOS</div><progress id="status-progress"></progress>')
    }
    if ($htmlText -notmatch 'Pantalla visible antes') {
        $htmlText = $htmlText.Replace('</style>', $style + "`r`n`t`t</style>")
    }
    Set-Content -LiteralPath $html.FullName -Value $htmlText -Encoding utf8
}

$background = Join-Path $ProjectDirectory 'assets\backgrounds\menu_apocalypse.png'
Copy-Item -LiteralPath $background -Destination (Join-Path $ExportDirectory 'loading-backdrop.png') -Force
