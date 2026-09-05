<#
    Build this CV and report whether it still fits.

    Usage, from anywhere:
        pwsh -File "<this folder>\build.ps1"

    Reports page count, any overfull/underfull boxes, and how far down the
    last page the content ends. That last figure is the one to watch: the
    layout is tuned to land just inside two pages, so a fill above ~96%
    means the next sentence you add will spill onto a third page.

    Auxiliary files are written to a temp directory, so this folder keeps
    only the .tex sources and the finished PDF.
#>

param(
    # Output filename. Change this when the CV rolls to a new quarter.
    [string] $PdfName = 'CV_Satria_Hadiwijaya_2026_Q3.pdf',
    # Set to keep the rendered page PNGs for inspection.
    [switch] $Png
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

# MiKTeX installs user-scope and does not put itself on PATH.
$candidates = @(
    "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64",
    "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin",
    "C:\Program Files\MiKTeX\miktex\bin\x64"
)
$bin = $candidates | Where-Object { Test-Path "$_\pdflatex.exe" } | Select-Object -First 1
if (-not $bin) {
    $onPath = Get-Command pdflatex -ErrorAction SilentlyContinue
    if ($onPath) { $bin = Split-Path $onPath.Source }
}
if (-not $bin) {
    Write-Host "pdflatex not found. Install MiKTeX with:" -ForegroundColor Red
    Write-Host "  winget install --id MiKTeX.MiKTeX --exact --scope user"
    exit 1
}

$out = Join-Path $env:TEMP ("cvbuild-" + (Split-Path $src -Leaf))
New-Item -ItemType Directory -Force $out | Out-Null

# Twice: hyperref needs a second pass to settle its outlines.
Push-Location $src
try {
    1..2 | ForEach-Object {
        & "$bin\pdflatex.exe" -interaction=nonstopmode -halt-on-error `
            -file-line-error -output-directory="$out" main.tex 2>&1 | Out-Null
    }
    $code = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($code -ne 0) {
    Write-Host "BUILD FAILED (exit $code)" -ForegroundColor Red
    Select-String -Path "$out\main.log" -Pattern '^!|^\.[\\/].*:\d+:' |
        Select-Object -First 15 | ForEach-Object { "  $_" }
    exit 1
}

$log      = Get-Content "$out\main.log" -Raw
$pages    = [regex]::Match($log, '\((\d+) pages').Groups[1].Value
$overfull = [regex]::Matches($log, 'Overfull .hbox').Count
$under    = [regex]::Matches($log, 'Underfull .hbox').Count
$warn     = [regex]::Matches($log, 'LaTeX Warning').Count

Copy-Item "$out\main.pdf" (Join-Path $src $PdfName) -Force

# Measure the lowest ink on the final page to see how much room is left.
# Clear old renders first: a stale pg-3.png from a previous overflowing
# build would otherwise be picked up as "the last page" and report a
# nonsense fill figure for a document that now runs to two pages.
Get-ChildItem "$out\pg-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force
& "$bin\pdftoppm.exe" -png -r 110 (Join-Path $src $PdfName) "$out\pg" 2>&1 | Out-Null
Add-Type -AssemblyName System.Drawing
$last = Get-ChildItem "$out\pg-*.png" | Sort-Object Name | Select-Object -Last 1
$bmp = [System.Drawing.Bitmap]::FromFile($last.FullName)
$bottom = 0
for ($y = $bmp.Height - 1; $y -ge 0 -and $bottom -eq 0; $y--) {
    for ($x = 0; $x -lt $bmp.Width; $x += 3) {
        if ($bmp.GetPixel($x, $y).R -lt 200) { $bottom = $y; break }
    }
}
$fill = [math]::Round(100.0 * $bottom / $bmp.Height, 1)
$bmp.Dispose()

if ($Png) { Copy-Item "$out\pg-*.png" $src -Force }

$pagesOk = ($pages -eq '2')
Write-Host ("pages          : {0}" -f $pages) -ForegroundColor $(if ($pagesOk) {'Green'} else {'Red'})
Write-Host ("overfull hbox  : {0}" -f $overfull) -ForegroundColor $(if ($overfull -eq 0) {'Green'} else {'Yellow'})
Write-Host ("underfull hbox : {0}" -f $under)
Write-Host ("latex warnings : {0}" -f $warn)
Write-Host ("last page fill : {0}%" -f $fill) -ForegroundColor $(if ($fill -lt 96) {'Green'} else {'Yellow'})
Write-Host ("written        : {0}" -f (Join-Path $src $PdfName))
if (-not $pagesOk) { Write-Host "`nNot two pages. Trim a bullet or tighten config.sty spacing." -ForegroundColor Red }
