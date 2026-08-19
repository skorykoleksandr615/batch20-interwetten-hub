Add-Type -AssemblyName System.Drawing
$root = "C:\AndroidStudioProjects\batch20-hubs\interwetten"

function Save-Jpeg($srcPath, $maxSide, $quality) {
  $img = [System.Drawing.Image]::FromFile($srcPath)
  $w = $img.Width; $h = $img.Height
  if ([Math]::Max($w, $h) -gt $maxSide) {
    $scale = $maxSide / [Math]::Max($w, $h)
    $nw = [int]($w * $scale); $nh = [int]($h * $scale)
  } else { $nw = $w; $nh = $h }
  $bmp = New-Object System.Drawing.Bitmap $nw, $nh
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.DrawImage($img, 0, 0, $nw, $nh)
  $img.Dispose()
  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
  $ep = New-Object System.Drawing.Imaging.EncoderParameters 1
  $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
  $tmp = $srcPath + ".tmp.jpg"
  $bmp.Save($tmp, $codec, $ep)
  $g.Dispose(); $bmp.Dispose()
  Move-Item -Force $tmp $srcPath
}

function Save-PngIcon($srcPath, $size, $outPath) {
  $img = [System.Drawing.Image]::FromFile($srcPath)
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::FromArgb(255, 17, 17, 17))
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $scale = [Math]::Min($size / $img.Width, $size / $img.Height)
  $nw = [int]($img.Width * $scale); $nh = [int]($img.Height * $scale)
  $x = [int](($size - $nw) / 2); $y = [int](($size - $nh) / 2)
  $g.DrawImage($img, $x, $y, $nw, $nh)
  $img.Dispose()
  $tmp = $outPath + ".tmp.png"
  $bmp.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Move-Item -Force $tmp $outPath
}

$logo = Join-Path $root "assets\brand\logo.png"
Save-PngIcon $logo 512 $logo
Write-Output ("logo {0}" -f (Get-Item $logo).Length)

Get-ChildItem -Recurse $root -Filter *.jpg | ForEach-Object {
  $max = 900
  if ($_.Name -in @("hero.jpg","og.jpg") -or $_.Directory.Name -in @("promo","pages")) { $max = 1600 }
  Save-Jpeg $_.FullName $max 78
  Write-Output ("{0} {1}" -f $_.Name, (Get-Item $_.FullName).Length)
}

foreach ($pair in @(
  @("favicon-48x48.png", 48),
  @("favicon-96x96.png", 96),
  @("favicon-192x192.png", 192),
  @("apple-touch-icon.png", 180)
)) {
  $out = Join-Path $root $pair[0]
  Save-PngIcon $logo $pair[1] $out
  Write-Output ("{0} {1}" -f $pair[0], (Get-Item $out).Length)
}
Copy-Item -Force (Join-Path $root "favicon-48x48.png") (Join-Path $root "favicon.ico")
Write-Output "done"
