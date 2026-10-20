<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('group_call_sessions', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('room_name')->unique();
            $table->foreignId('host_id')->constrained('users')->cascadeOnDelete();
            $table->string('status')->default('ringing');
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
            $table->index(['host_id', 'status']);
            $table->index(['status', 'expires_at']);
        });

        Schema::create('group_call_participants', function (Blueprint $table): void {
            $table->id();
            $table->foreignUuid('group_call_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('participant');
            $table->string('status')->default('invited');
            $table->timestamp('joined_at')->nullable();
            $table->timestamp('left_at')->nullable();
            $table->timestamps();
            $table->unique(['group_call_session_id', 'user_id']);
            $table->index(['user_id', 'status']);
        });

        Schema::create('device_push_tokens', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('token', 512)->unique();
            $table->string('platform', 16);
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'platform']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_push_tokens');
        Schema::dropIfExists('group_call_participants');
        Schema::dropIfExists('group_call_sessions');
    }
};
