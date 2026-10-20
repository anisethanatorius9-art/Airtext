<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('statuses', function (Blueprint $table): void {
            $table->boolean('view_once')->default(false);
            $table->boolean('screenshot_protected')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('statuses', function (Blueprint $table): void {
            $table->dropColumn(['view_once', 'screenshot_protected']);
        });
    }
};
