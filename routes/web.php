<?php

use App\Livewire\WhatsAppChat;
use Illuminate\Support\Facades\Route;

Route::get('/', WhatsAppChat::class)->name('home');
Route::redirect('dashboard', '/')->name('dashboard');

require __DIR__.'/settings.php';
