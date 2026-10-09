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

function Save-AirTextIcon([string]$filePath, [bool]$background, [bool]$foregroundOnly) {
    $bitmap = New-Object System.Drawing.Bitmap(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    if ($background) {
        $base = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 18, 59, 80))
        $graphics.FillRectangle($base, 0, 0, 1024, 1024)
        $base.Dispose()
    }

    if ($foregroundOnly) {
        $x = 230; $y = 250; $width = 564; $height = 350; $radius = 76
        $tailPoints = @([System.Drawing.Point]::new(276, 560), [System.Drawing.Point]::new(260, 742), [System.Drawing.Point]::new(450, 585))
        $line1 = [System.Drawing.Point]::new(335, 355); $line2 = [System.Drawing.Point]::new(690, 355)
        $line3 = [System.Drawing.Point]::new(335, 430); $line4 = [System.Drawing.Point]::new(545, 430)
        $pulsePoints = @([System.Drawing.Point]::new(545, 530), [System.Drawing.Point]::new(590, 486), [System.Drawing.Point]::new(635, 530), [System.Drawing.Point]::new(704, 450))
    } else {
        $x = 190; $y = 205; $width = 644; $height = 470; $radius = 94
        $tailPoints = @([System.Drawing.Point]::new(250, 625), [System.Drawing.Point]::new(216, 826), [System.Drawing.Point]::new(452, 642))
        $line1 = [System.Drawing.Point]::new(320, 350); $line2 = [System.Drawing.Point]::new(700, 350)
        $line3 = [System.Drawing.Point]::new(320, 445); $line4 = [System.Drawing.Point]::new(555, 445)
        $pulsePoints = @([System.Drawing.Point]::new(560, 570), [System.Drawing.Point]::new(612, 518), [System.Drawing.Point]::new(664, 570), [System.Drawing.Point]::new(750, 470))
    }

    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $bubble = New-RoundedPath $x $y $width $height $radius
    $graphics.FillPath($white, $bubble)
    $tail = New-Object System.Drawing.Drawing2D.GraphicsPath
    $tail.AddPolygon($tailPoints)
    $graphics.FillPath($white, $tail)

    $ink = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 18, 59, 80), 28)
    $ink.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $ink.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($ink, $line1, $line2)
    $graphics.DrawLine($ink, $line3, $line4)

    $signal = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 190, 85), 27)
    $signal.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $signal.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $signal.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $graphics.DrawLines($signal, $pulsePoints)

    $bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
    $signal.Dispose()
    $ink.Dispose()
    $tail.Dispose()
    $bubble.Dispose()
    $white.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$assets = Join-Path $PSScriptRoot '..\assets'
Save-AirTextIcon (Join-Path $assets 'airtext_app_icon.png') $true $false
Save-AirTextIcon (Join-Path $assets 'airtext_adaptive_foreground.png') $false $true
