Add-Type -AssemblyName System.Drawing

$width = 960
$height = 280

$bmp = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# White background
$g.Clear([System.Drawing.Color]::White)

# 1. Brasao on the left
$brasaoPath = 'd:\Projeto APK Patrimonio\brasao.png'
if (Test-Path $brasaoPath) {
    $brasaoImg = [System.Drawing.Image]::FromFile($brasaoPath)
    $destRect = New-Object System.Drawing.Rectangle(18, 22, 225, 235)
    $g.DrawImage($brasaoImg, $destRect)
    $brasaoImg.Dispose()
}

# 2. QR Code on the right
$qrData = Get-Content 'd:\Projeto APK Patrimonio\qr_matrix.json' | ConvertFrom-Json
$count = $qrData.count
$qrSize = 215
$qrX = 705
$qrY = 32
$modSize = [float]$qrSize / $count

$blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(15, 15, 15))
for ($r = 0; $r -lt $count; $r++) {
    for ($c = 0; $c -lt $count; $c++) {
        if ($qrData.matrix[$r][$c] -eq 1) {
            $x = $qrX + ($c * $modSize)
            $y = $qrY + ($r * $modSize)
            $g.FillRectangle($blackBrush, [float]$x, [float]$y, [float]($modSize + 0.35), [float]($modSize + 0.35))
        }
    }
}

# 3. Center Texts
$fontTombo = New-Object System.Drawing.Font('Arial', 32, [System.Drawing.FontStyle]::Bold)
$fontDesc = New-Object System.Drawing.Font('Arial', 21, [System.Drawing.FontStyle]::Bold)
$fontLocal = New-Object System.Drawing.Font('Arial', 20, [System.Drawing.FontStyle]::Regular)

# Tombo: PAT-0000029794
$tomboText = 'PAT-0000029794'
$tomboSize = $g.MeasureString($tomboText, $fontTombo)
# Center the tombo in the column zone (250 to 695)
$colWidth = 695 - 250
$tomboX = 250 + (($colWidth - $tomboSize.Width) / 2)
$g.DrawString($tomboText, $fontTombo, $blackBrush, [float]$tomboX, [float]30)

# Descricao: COMPUTADOR DESKTOP
$descX = 250
$descY = 96
$g.DrawString('COMPUTADOR DESKTOP', $fontDesc, $blackBrush, [float]$descX, [float]$descY)

# Local: SECRETARIA DE ASSISTENCIA SOCIAL
$localY = 140
$localRect = New-Object System.Drawing.RectangleF($descX, $localY, 445, 105)
$strFormat = New-Object System.Drawing.StringFormat
$strFormat.LineAlignment = [System.Drawing.StringAlignment]::Near
$strFormat.Alignment = [System.Drawing.StringAlignment]::Near
$g.DrawString("SECRETARIA DE ASSISTENCIA`nSOCIAL", $fontLocal, $blackBrush, $localRect, $strFormat)

# Subtle outer border
$borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(215, 215, 215), 2)
$g.DrawRectangle($borderPen, 1, 1, $width - 2, $height - 2)
$borderPen.Dispose()

$blackBrush.Dispose()
$fontTombo.Dispose()
$fontDesc.Dispose()
$fontLocal.Dispose()
$g.Dispose()

$outMockup = 'd:\Projeto APK Patrimonio\modelo_etiqueta_mockup.png'
$bmp.Save($outMockup, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Mockup with PAT-0000029794 rendered"
