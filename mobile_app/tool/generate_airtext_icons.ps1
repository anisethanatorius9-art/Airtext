Add-Type -AssemblyName System.Drawing

function New-RoundedPath([float]$x, [float]$y, [float]$width, [float]$height, [float]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = 2 * $radius
    $path.AddArc($x, $y, $diameter, $diameter, 180, 90)
    $path.AddArc($x + $width - $diameter, $y, $diameter, $diameter, 270, 90)
    $path.AddArc($x + $width - $diameter, $y + $height - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($x, $y + $height - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-AirTextMark($graphics, [bool]$foregroundOnly) {
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 248, 255, 255))
    $feather = New-Object System.Drawing.Drawing2D.GraphicsPath
    $feather.AddBezier(
        [System.Drawing.PointF]::new(30, 91),
        [System.Drawing.PointF]::new(38, 65),
        [System.Drawing.PointF]::new(60, 39),
        [System.Drawing.PointF]::new(96, 22)
    )
    $feather.AddBezier(
        [System.Drawing.PointF]::new(96, 22),
        [System.Drawing.PointF]::new(87, 49),
        [System.Drawing.PointF]::new(67, 72),
        [System.Drawing.PointF]::new(30, 91)
    )
    $feather.CloseFigure()
    $graphics.FillPath($white, $feather)

    if (-not $foregroundOnly) {
        $cut = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 16, 183, 177), 3.2)
        $cut.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $cut.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $graphics.DrawLine($cut, 39, 82, 79, 48)
        $graphics.DrawLine($cut, 49, 73, 88, 39)
        $graphics.DrawLine($cut, 59, 64, 91, 30)
        $cut.Dispose()
    }

    $chat = New-Object System.Drawing.Drawing2D.GraphicsPath
    $chat.AddBezier(
        [System.Drawing.PointF]::new(44, 28),
        [System.Drawing.PointF]::new(29, 30),
        [System.Drawing.PointF]::new(22, 42),
        [System.Drawing.PointF]::new(26, 55)
    )
    $chat.AddBezier(
        [System.Drawing.PointF]::new(26, 55),
        [System.Drawing.PointF]::new(28, 65),
        [System.Drawing.PointF]::new(34, 71),
        [System.Drawing.PointF]::new(42, 75)
    )
    $chat.AddBezier(
        [System.Drawing.PointF]::new(42, 75),
        [System.Drawing.PointF]::new(51, 92),
        [System.Drawing.PointF]::new(68, 96),
        [System.Drawing.PointF]::new(78, 89)
    )
    $chat.AddLine(78, 89, 85, 96)
    $chat.AddLine(85, 96, 83, 82)
    $chat.AddBezier(
        [System.Drawing.PointF]::new(83, 82),
        [System.Drawing.PointF]::new(87, 77),
        [System.Drawing.PointF]::new(90, 72),
        [System.Drawing.PointF]::new(91, 65)
    )
    $outline = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 248, 255, 255), 2.8)
    $outline.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $outline.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $outline.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawPath($outline, $chat)

    $shield = New-Object System.Drawing.Drawing2D.GraphicsPath
    $shield.AddPolygon(@(
        [System.Drawing.PointF]::new(99, 83),
        [System.Drawing.PointF]::new(111, 87),
        [System.Drawing.PointF]::new(109, 99),
        [System.Drawing.PointF]::new(99, 108),
        [System.Drawing.PointF]::new(89, 99),
        [System.Drawing.PointF]::new(87, 87)
    ))
    $shieldColor = if ($foregroundOnly) {
        [System.Drawing.Color]::FromArgb(255, 248, 255, 255)
    } else {
        [System.Drawing.Color]::FromArgb(255, 146, 244, 240)
    }
    $shieldBrush = New-Object System.Drawing.SolidBrush($shieldColor)
    $graphics.FillPath($shieldBrush, $shield)

    if (-not $foregroundOnly) {
        $star = New-Object System.Drawing.Drawing2D.GraphicsPath
        $star.AddPolygon(@(
            [System.Drawing.PointF]::new(99, 88),
            [System.Drawing.PointF]::new(101, 94),
            [System.Drawing.PointF]::new(106, 96),
            [System.Drawing.PointF]::new(101, 98),
            [System.Drawing.PointF]::new(99, 103),
            [System.Drawing.PointF]::new(97, 98),
            [System.Drawing.PointF]::new(92, 96),
            [System.Drawing.PointF]::new(97, 94)
        ))
        $starBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 11, 159, 155))
        $graphics.FillPath($starBrush, $star)
        $starBrush.Dispose()
        $star.Dispose()
    }

    $shieldBrush.Dispose()
    $shield.Dispose()
    $outline.Dispose()
    $chat.Dispose()
    $feather.Dispose()
    $white.Dispose()
}

function Save-AirTextIcon([string]$filePath, [bool]$background, [bool]$foregroundOnly) {
    $bitmap = New-Object System.Drawing.Bitmap(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    if ($background) {
        $shadowPath = New-RoundedPath 88 100 848 848 190
        $shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(48, 0, 80, 93))
        $graphics.FillPath($shadow, $shadowPath)
        $tile = New-RoundedPath 88 76 848 848 190
        $bounds = New-Object System.Drawing.Rectangle(88, 76, 848, 848)
        $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $bounds,
            [System.Drawing.Color]::FromArgb(255, 8, 151, 127),
            [System.Drawing.Color]::FromArgb(255, 17, 207, 219),
            42
        )
        $graphics.FillPath($gradient, $tile)
        $edge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(68, 255, 255, 255), 3)
        $graphics.DrawPath($edge, $tile)
        $edge.Dispose()
        $gradient.Dispose()
        $shadow.Dispose()
        $tile.Dispose()
        $shadowPath.Dispose()
    }

    $markScale = 5.2
    $offset = (1024 - (126 * $markScale)) / 2
    $matrix = New-Object System.Drawing.Drawing2D.Matrix($markScale, 0, 0, $markScale, $offset, $offset)
    $graphics.Transform = $matrix
    Draw-AirTextMark $graphics $foregroundOnly

    $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $matrix.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$assets = Join-Path $PSScriptRoot '..\assets'
Save-AirTextIcon (Join-Path $assets 'airtext_app_icon.png') $true $false
Save-AirTextIcon (Join-Path $assets 'airtext_adaptive_foreground.png') $false $true
