<?php

use App\Livewire\WhatsAppChat;
use App\Http\Controllers\Api\ConversationController;
use Illuminate\Support\Facades\Route;

Route::get('/', WhatsAppChat::class)->name('home');
Route::get('/conversations/{conversation}/messages/{message}/attachment', [ConversationController::class, 'attachment'])
	->middleware('auth')
	->name('chat.attachments.show');
Route::redirect('dashboard', '/')->name('dashboard');

require __DIR__ . '/settings.php';
