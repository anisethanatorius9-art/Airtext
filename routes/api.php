<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ConversationController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('otp/request', [AuthController::class, 'requestCode'])->middleware('throttle:3,1');
    Route::post('otp/verify', [AuthController::class, 'verifyCode'])->middleware('throttle:10,1');
});

Route::middleware('auth:sanctum')->group(function () {
    Route::get('me', [AuthController::class, 'me']);
    Route::delete('auth/token', [AuthController::class, 'logout']);
    Route::get('conversations', [ConversationController::class, 'index']);
    Route::post('conversations', [ConversationController::class, 'store']);
    Route::post('conversations/{conversation}/messages', [ConversationController::class, 'send']);
    Route::post('conversations/{conversation}/read', [ConversationController::class, 'markRead']);
});
