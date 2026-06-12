Add-Type -AssemblyName System.Drawing

function New-CaveIcon([int]$size, [string]$outPath) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'

  $s = $size / 512.0

  # Fond espresso avec léger dégradé radial simulé (deux remplissages)
  $bgDark = [System.Drawing.Color]::FromArgb(20, 10, 3)
  $g.Clear($bgDark)
  $warm = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(28, 42, 24, 8))
  $g.FillEllipse($warm, [float](-100*$s), [float](-150*$s), [float](700*$s), [float](500*$s))

  # Cadre doré fin
  $goldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 212, 160, 23), [float](6*$s))
  $g.DrawRectangle($goldPen, [float](24*$s), [float](24*$s), [float](464*$s), [float](464*$s))

  # Verre (tumbler) — contour or
  $glassPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 224, 172, 40), [float](14*$s))
  $glassPen.LineJoin = 'Round'

  # points du verre : trapèze léger
  $topY = 150*$s; $botY = 390*$s
  $tl = 160*$s; $tr = 352*$s   # top gauche/droite
  $bl = 176*$s; $br = 336*$s   # bas gauche/droite

  # Liquide ambré (sous la moitié)
  $liqTop = 255*$s
  # largeur du verre au niveau liqTop (interpolation)
  $f = ($liqTop - $topY) / ($botY - $topY)
  $ll = $tl + ($bl - $tl) * $f
  $lr = $tr + ($br - $tr) * $f
  $liquid = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 200, 112, 16))
  $pts = @(
    (New-Object System.Drawing.PointF([float]$ll, [float]$liqTop)),
    (New-Object System.Drawing.PointF([float]$lr, [float]$liqTop)),
    (New-Object System.Drawing.PointF([float]$br, [float]$botY)),
    (New-Object System.Drawing.PointF([float]$bl, [float]$botY))
  )
  $g.FillPolygon($liquid, $pts)
  # surface du liquide plus claire
  $surf = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 232, 146, 26))
  $g.FillRectangle($surf, [float]$ll, [float]$liqTop, [float]($lr-$ll), [float](14*$s))

  # contour du verre par-dessus
  $g.DrawLine($glassPen, [float]$tl, [float]$topY, [float]$bl, [float]$botY)
  $g.DrawLine($glassPen, [float]$tr, [float]$topY, [float]$br, [float]$botY)
  $g.DrawLine($glassPen, [float]$bl, [float]$botY, [float]$br, [float]$botY)
  # bord supérieur fin
  $rimPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 224, 172, 40), [float](8*$s))
  $g.DrawLine($rimPen, [float]$tl, [float]$topY, [float]$tr, [float]$topY)

  # reflet vertical
  $shinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 255, 240, 200), [float](10*$s))
  $shinePen.StartCap = 'Round'; $shinePen.EndCap = 'Round'
  $g.DrawLine($shinePen, [float](190*$s), [float](175*$s), [float](198*$s), [float](235*$s))

  # double filet décoratif bas (style étiquette)
  $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 212, 160, 23), [float](4*$s))
  $g.DrawLine($linePen, [float](120*$s), [float](436*$s), [float](392*$s), [float](436*$s))

  $g.Dispose()
  $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host "OK $outPath"
}

$root = Split-Path -Parent $PSScriptRoot
New-CaveIcon 512 (Join-Path $PSScriptRoot 'icon-512.png')
New-CaveIcon 192 (Join-Path $PSScriptRoot 'icon-192.png')
New-CaveIcon 180 (Join-Path $root 'apple-touch-icon.png')
