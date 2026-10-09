<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->foreignId('owner_id')->nullable()->after('id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('recipient_id')->nullable()->after('owner_id')->constrained('users')->nullOnDelete();
            $table->string('recipient_email')->nullable()->after('recipient_id');
            $table->index(['owner_id', 'recipient_id']);
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->foreignId('sender_id')->nullable()->after('conversation_id')->constrained('users')->nullOnDelete();
        });

        DB::table('messages')->orderBy('id')->chunkById(100, function ($messages): void {
            foreach ($messages as $message) {
                DB::table('messages')
                    ->where('id', $message->id)
                    ->update(['body' => Crypt::encryptString($message->body)]);
            }
        });
    }

    public function down(): void
    {
        DB::table('messages')->orderBy('id')->chunkById(100, function ($messages): void {
            foreach ($messages as $message) {
                DB::table('messages')
                    ->where('id', $message->id)
                    ->update(['body' => Crypt::decryptString($message->body)]);
            }
        });

        Schema::table('messages', function (Blueprint $table) {
            $table->dropConstrainedForeignId('sender_id');
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->dropIndex(['owner_id', 'recipient_id']);
            $table->dropConstrainedForeignId('recipient_id');
            $table->dropConstrainedForeignId('owner_id');
            $table->dropColumn('recipient_email');
        });
    }
};
