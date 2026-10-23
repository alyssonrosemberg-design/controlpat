Add-Type -AssemblyName System.Drawing

$imgOrig = [System.Drawing.Image]::FromFile('d:\Projeto APK Patrimonio\etiqueta_original_crop.png')
$imgMock = [System.Drawing.Image]::FromFile('d:\Projeto APK Patrimonio\modelo_etiqueta_mockup.png')

$totalW = 1000
$totalH = 750

$bmp = New-Object System.Drawing.Bitmap($totalW, $totalH)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

$g.Clear([System.Drawing.Color]::FromArgb(245, 247, 250))

$titleFont = New-Object System.Drawing.Font('Arial', 14, [System.Drawing.FontStyle]::Bold)
$titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60, 60, 60))
$greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(16, 120, 60))

# 1. Original Section
$g.DrawString("1. ETIQUETA ORIGINAL (FOTO ANEXADA)", $titleFont, $titleBrush, 20, 20)
# Draw original crop (approx 960x280)
$destOrig = New-Object System.Drawing.Rectangle(20, 50, 960, 280)
$g.DrawImage($imgOrig, $destOrig)

# 2. Separator line
$pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 215, 225), 2)
$g.DrawLine($pen, 20, 360, 980, 360)
$pen.Dispose()

# 3. Proposed Model Section
$g.DrawString("2. NOVO MODELO DIGITAL PROPOSTO PARA O SISTEMA", $titleFont, $greenBrush, 20, 385)
$destMock = New-Object System.Drawing.Rectangle(20, 415, 960, 280)
$g.DrawImage($imgMock, $destMock)

$titleFont.Dispose()
$titleBrush.Dispose()
$greenBrush.Dispose()
$imgOrig.Dispose()
$imgMock.Dispose()
$g.Dispose()

$compPath = 'd:\Projeto APK Patrimonio\comparativo_etiquetas.png'
$bmp.Save($compPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Comparative generated at $compPath"
