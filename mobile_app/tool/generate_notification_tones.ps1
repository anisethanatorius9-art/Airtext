$ErrorActionPreference = 'Stop'

$androidDirectory = Join-Path $PSScriptRoot '..\android\app\src\main\res\raw'
$iosDirectory = Join-Path $PSScriptRoot '..\ios\Runner\NotificationSounds'
New-Item -ItemType Directory -Force -Path $androidDirectory, $iosDirectory | Out-Null

function New-ToneWave([int]$frequency, [double]$durationSeconds) {
    $sampleRate = 16000
    $sampleCount = [int]($sampleRate * $durationSeconds)
    $stream = New-Object System.IO.MemoryStream
    $writer = New-Object System.IO.BinaryWriter($stream)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
    $writer.Write([int](36 + $sampleCount * 2))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
    $writer.Write([int]16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write([int]$sampleRate)
    $writer.Write([int]($sampleRate * 2))
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
    $writer.Write([int]($sampleCount * 2))

    for ($index = 0; $index -lt $sampleCount; $index++) {
        $progress = $index / $sampleCount
        $fade = [Math]::Min(1.0, [Math]::Min($progress * 18, (1 - $progress) * 18))
        $sample = [Math]::Sin(2 * [Math]::PI * $frequency * $index / $sampleRate)
        $writer.Write([int16][Math]::Round($sample * $fade * 10000))
    }

    $writer.Flush()
    $bytes = $stream.ToArray()
    $writer.Dispose()
    $stream.Dispose()
    return ,$bytes
}

$tones = @(
    @{ Name = 'airtext_chime'; Frequency = 880 },
    @{ Name = 'airtext_modern_ping'; Frequency = 1175 },
    @{ Name = 'airtext_soft_echo'; Frequency = 660 }
)

foreach ($tone in $tones) {
    $bytes = New-ToneWave $tone.Frequency 0.22
    [System.IO.File]::WriteAllBytes((Join-Path $androidDirectory "$($tone.Name).wav"), $bytes)
    [System.IO.File]::WriteAllBytes((Join-Path $iosDirectory "$($tone.Name).wav"), $bytes)
}
