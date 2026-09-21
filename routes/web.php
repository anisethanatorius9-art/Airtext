<?php

use Illuminate\Support\Facades\Route;
use App\Livewire\WhatsAppChat;

Route::get('/', WhatsAppChat::class)->name('home');
Route::redirect('dashboard', '/')->name('dashboard');

require __DIR__.'/settings.php';
