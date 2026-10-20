<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('channels', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->string('avatar_path')->nullable();
            $table->boolean('is_public')->default(true);
            $table->timestamps();
        });

        Schema::create('channel_members', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('channel_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('follower');
            $table->timestamp('joined_at')->nullable();
            $table->timestamps();
            $table->unique(['channel_id', 'user_id']);
            $table->index(['user_id', 'channel_id']);
        });

        Schema::create('channel_posts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('channel_id')->constrained()->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->text('body')->nullable();
            $table->string('media_path')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();
            $table->index(['channel_id', 'published_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('channel_posts');
        Schema::dropIfExists('channel_members');
        Schema::dropIfExists('channels');
    }
};
