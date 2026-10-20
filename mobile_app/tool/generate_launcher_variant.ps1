$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$sourcePath = Join-Path $PSScriptRoot '..\assets\airtext_app_icon.png'
$source = [System.Drawing.Bitmap]::new($sourcePath)
$variant = [System.Drawing.Bitmap]::new($source.Width, $source.Height)

for ($y = 0; $y -lt $source.Height; $y++) {
    for ($x = 0; $x -lt $source.Width; $x++) {
        $pixel = $source.GetPixel($x, $y)
        if ($pixel.A -eq 0) {
            $variant.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
        } elseif ($pixel.R -gt 224 -and $pixel.G -gt 224 -and $pixel.B -gt 224) {
            $variant.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, 248, 255, 255))
        } else {
            $variant.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, 16, 43, 58))
        }
    }
}

$androidRoot = Join-Path $PSScriptRoot '..\android\app\src\main\res'
$sizes = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($entry in $sizes.GetEnumerator()) {
    $directory = Join-Path $androidRoot $entry.Key
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $image = [System.Drawing.Bitmap]::new($entry.Value, $entry.Value)
    $graphics = [System.Drawing.Graphics]::FromImage($image)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($variant, 0, 0, $entry.Value, $entry.Value)
    $image.Save((Join-Path $directory 'ic_launcher_midnight.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $image.Dispose()
}

$iosDirectory = Join-Path $PSScriptRoot '..\ios\Runner\Assets.xcassets\AppIconMidnight.appiconset'
New-Item -ItemType Directory -Force -Path $iosDirectory | Out-Null
$variant.Save((Join-Path $iosDirectory 'AppIconMidnight.png'), [System.Drawing.Imaging.ImageFormat]::Png)
@'
{
  "images": [
    {
      "filename": "AppIconMidnight.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
'@ | Set-Content -Encoding UTF8 (Join-Path $iosDirectory 'Contents.json')

$variant.Dispose()
$source.Dispose()
