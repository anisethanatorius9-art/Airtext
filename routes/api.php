<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CallController;
use App\Http\Controllers\Api\ChannelController;
use App\Http\Controllers\Api\ContactController;
use App\Http\Controllers\Api\ContactSyncController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\DevicePushTokenController;
use App\Http\Controllers\Api\GroupCallController;
use App\Http\Controllers\Api\PresenceController;
use App\Http\Controllers\Api\ShopController;
use App\Http\Controllers\Api\StatusController;
use App\Http\Controllers\Api\SmsGatewayController;
use App\Http\Controllers\Api\StorageSummaryController;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('otp/request', [AuthController::class, 'requestCode'])->middleware('throttle:3,1');
    Route::post('otp/verify', [AuthController::class, 'verifyCode'])->middleware('throttle:10,1');
    Route::post('phone/otp/verify-login', [AuthController::class, 'verifyPhoneLoginCode'])->middleware('throttle:10,1');
});

Route::middleware(['auth:sanctum', 'abilities:phone-verification'])->group(function () {
    Route::put('me/profile', [AuthController::class, 'updateProfile']);
    Route::post('auth/phone/otp/request', [AuthController::class, 'requestPhoneCode'])->middleware('throttle:3,1');
    Route::post('auth/phone/otp/verify', [AuthController::class, 'verifyPhoneCode'])->middleware('throttle:10,1');
});

Route::post('shop/payment-callback', [ShopController::class, 'paymentCallback'])
    ->middleware('throttle:60,1');

Route::middleware(['auth:sanctum', 'abilities:app'])->group(function () {
    Broadcast::routes(['middleware' => ['auth:sanctum', 'abilities:app']]);

    Route::get('me', [AuthController::class, 'me']);
    Route::post('me/profile-photo', [AuthController::class, 'updateProfilePhoto']);
    Route::delete('me/profile-photo', [AuthController::class, 'deleteProfilePhoto']);
    Route::post('me/presence', [PresenceController::class, 'heartbeat'])->middleware('throttle:60,1');
    Route::delete('me', [AuthController::class, 'destroy']);
    Route::get('me/preferences', [AuthController::class, 'preferences']);
    Route::put('me/preferences', [AuthController::class, 'updatePreferences']);
    Route::get('me/sms-gateway', [SmsGatewayController::class, 'show']);
    Route::post('me/sms-gateway/test', [SmsGatewayController::class, 'test']);
    Route::get('me/storage-summary', [StorageSummaryController::class, 'show']);
    Route::put('me/contacts', [ContactSyncController::class, 'sync']);
    Route::get('contacts', [ContactController::class, 'index']);
    Route::post('contacts', [ContactController::class, 'store']);
    Route::delete('auth/token', [AuthController::class, 'logout']);
    Route::get('conversations', [ConversationController::class, 'index']);
    Route::post('conversations', [ConversationController::class, 'store']);
    Route::post('conversations/{conversation}/messages', [ConversationController::class, 'send']);
    Route::post('conversations/{conversation}/messages/local-sms', [ConversationController::class, 'recordLocalSms']);
    Route::post('conversations/{conversation}/messages/{message}/view-once', [ConversationController::class, 'openViewOnce']);
    Route::get('conversations/{conversation}/messages/{message}/media', [ConversationController::class, 'voiceMedia']);
    Route::post('conversations/{conversation}/typing', [ConversationController::class, 'typing']);
    Route::get('conversations/{conversation}/typing', [ConversationController::class, 'typingStatus']);
    Route::post('conversations/{conversation}/messages/{message}/translate', [ConversationController::class, 'translateMessage'])->middleware('throttle:20,1');
    Route::post('conversations/{conversation}/read', [ConversationController::class, 'markRead']);
    Route::get('statuses', [StatusController::class, 'index']);
    Route::post('statuses', [StatusController::class, 'store']);
    Route::post('statuses/{status}/view', [StatusController::class, 'markViewed']);
    Route::get('statuses/{status}/viewers', [StatusController::class, 'viewers']);
    Route::get('statuses/{status}/likes', [StatusController::class, 'likers']);
    Route::post('statuses/{status}/like', [StatusController::class, 'like']);
    Route::delete('statuses/{status}/like', [StatusController::class, 'unlike']);
    Route::get('channels', [ChannelController::class, 'index']);
    Route::post('channels', [ChannelController::class, 'store']);
    Route::get('channels/{channel}', [ChannelController::class, 'show']);
    Route::post('channels/{channel}/join', [ChannelController::class, 'join']);
    Route::post('channels/{channel}/leave', [ChannelController::class, 'leave']);
    Route::get('channels/{channel}/posts', [ChannelController::class, 'posts']);
    Route::post('channels/{channel}/posts', [ChannelController::class, 'storePost']);
    Route::get('calls/ice-servers', [CallController::class, 'iceServers']);
    Route::get('calls/active', [CallController::class, 'active']);
    Route::post('calls', [CallController::class, 'store']);
    Route::get('calls/{callSession}', [CallController::class, 'show']);
    Route::post('calls/{callSession}/accept', [CallController::class, 'accept']);
    Route::post('calls/{callSession}/decline', [CallController::class, 'decline']);
    Route::post('calls/{callSession}/signals', [CallController::class, 'signal']);
    Route::post('calls/{callSession}/end', [CallController::class, 'end']);
    Route::get('group-calls/active', [GroupCallController::class, 'active']);
    Route::post('group-calls', [GroupCallController::class, 'store']);
    Route::post('group-calls/{groupCallSession}/accept', [GroupCallController::class, 'accept']);
    Route::post('group-calls/{groupCallSession}/decline', [GroupCallController::class, 'decline']);
    Route::get('group-calls/{groupCallSession}/token', [GroupCallController::class, 'token']);
    Route::post('group-calls/{groupCallSession}/leave', [GroupCallController::class, 'leave']);
    Route::post('device-tokens', [DevicePushTokenController::class, 'store']);
    Route::delete('device-tokens', [DevicePushTokenController::class, 'destroy']);
    Route::post('shop/checkout', [ShopController::class, 'checkout']);
});
