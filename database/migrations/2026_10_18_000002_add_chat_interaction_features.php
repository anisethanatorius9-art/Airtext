<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->timestamp('last_seen_at')->nullable()->index();
            $table->string('profile_photo_path')->nullable();
        });

        Schema::table('messages', function (Blueprint $table): void {
            $table->string('message_type')->default('text');
            $table->string('media_path')->nullable();
            $table->boolean('view_once')->default(false);
            $table->timestamp('delivered_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('viewed_at')->nullable();
        });

        Schema::create('conversation_typing', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('activity')->default('typing');
            $table->timestamp('typing_until')->index();
            $table->timestamps();
            $table->unique(['conversation_id', 'user_id']);
        });

        Schema::create('status_likes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('status_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['status_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('status_likes');
        Schema::dropIfExists('conversation_typing');

        Schema::table('messages', function (Blueprint $table): void {
            $table->dropColumn([
                'message_type',
                'media_path',
                'view_once',
                'delivered_at',
                'read_at',
                'viewed_at',
            ]);
        });

        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['last_seen_at', 'profile_photo_path']);
        });
    }
};