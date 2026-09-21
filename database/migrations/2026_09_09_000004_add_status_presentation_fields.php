<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('statuses', function (Blueprint $table): void {
            $table->string('media_type')->default('text')->after('media_path');
            $table->text('caption')->nullable()->after('media_type');
            $table->string('background')->default('#00a884')->after('privacy');
            $table->string('font')->default('sans')->after('background');
            $table->string('author_name')->default('Contact')->after('font');
            $table->string('author_initials', 8)->default('?')->after('author_name');
            $table->boolean('is_viewed')->default(false)->after('author_initials');
        });
    }

    public function down(): void
    {
        Schema::table('statuses', function (Blueprint $table): void {
            $table->dropColumn([
                'media_type',
                'caption',
                'background',
                'font',
                'author_name',
                'author_initials',
                'is_viewed',
            ]);
        });
    }
};
