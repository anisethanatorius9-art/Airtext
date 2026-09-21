<!doctype html>
<html lang="en">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AirText | SMS conversations</title>
    <link rel="icon" href="{{ asset('airtext-mark.svg') }}" type="image/svg+xml">
    <link rel="apple-touch-icon" href="{{ asset('airtext-mark.svg') }}">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @fluxAppearance
    @livewireStyles
</head>

<body class="whatsapp-body">
    {{ $slot }}
    <flux:toast.group>
        <flux:toast />
    </flux:toast.group>
    @livewireScripts
</body>

</html>
