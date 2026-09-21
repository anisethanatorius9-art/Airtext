<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('contacts')->insertOrIgnore([
            [
                'name' => 'Juma K.',
                'phone_number' => '+255712884102',
                'status_bio' => 'Available for SMS',
                'payload_prefix' => 'MSG:',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Lina A.',
                'phone_number' => '+255754991204',
                'status_bio' => 'STAT: Active this week',
                'payload_prefix' => 'MSG:',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        DB::table('contacts')->whereIn('phone_number', ['+255712884102', '+255754991204'])->delete();
    }
};
