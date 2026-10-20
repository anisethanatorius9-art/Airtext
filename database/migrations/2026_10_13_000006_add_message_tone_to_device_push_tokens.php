<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('device_push_tokens', function (Blueprint $table): void {
            $table->string('message_tone', 32)->default('Chime');
        });
    }

    public function down(): void
    {
        Schema::table('device_push_tokens', function (Blueprint $table): void {
            $table->dropColumn('message_tone');
        });
    }
};
