<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_network_usage', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('period_start');
            $table->unsignedBigInteger('uploaded_bytes')->default(0);
            $table->unsignedBigInteger('downloaded_bytes')->default(0);
            $table->unsignedBigInteger('request_count')->default(0);
            $table->timestamps();
            $table->unique(['user_id', 'period_start']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_network_usage');
    }
};
