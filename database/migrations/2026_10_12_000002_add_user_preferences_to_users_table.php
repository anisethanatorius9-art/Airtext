<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('app_language')->default('English')->after('phone_verified_at');
            $table->string('last_seen_visibility')->default('Everyone')->after('app_language');
            $table->string('profile_picture_visibility')->default('My contacts')->after('last_seen_visibility');
            $table->string('about_visibility')->default('My contacts')->after('profile_picture_visibility');
            $table->string('links_visibility')->default('My contacts')->after('about_visibility');
            $table->string('status_visibility')->default('Everyone')->after('links_visibility');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'app_language',
                'last_seen_visibility',
                'profile_picture_visibility',
                'about_visibility',
                'links_visibility',
                'status_visibility',
            ]);
        });
    }
};
