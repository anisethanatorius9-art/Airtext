<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('subscription_plans', function (Blueprint $table): void {
            $table->json('entitlements')->nullable();
        });

        DB::table('subscription_plans')->where('code', 'free_starter')->update([
            'entitlements' => json_encode([
                'ai_bots' => false,
                'storage_bytes' => 536870912,
                'priority_messaging' => false,
            ]),
        ]);
        DB::table('subscription_plans')->whereIn('code', ['pro_monthly', 'pro_quarterly'])->update([
            'entitlements' => json_encode([
                'ai_bots' => true,
                'storage_bytes' => 5368709120,
                'priority_messaging' => true,
            ]),
        ]);
        DB::table('subscription_plans')->whereIn('code', ['biz_monthly', 'biz_yearly'])->update([
            'entitlements' => json_encode([
                'ai_bots' => true,
                'storage_bytes' => null,
                'priority_messaging' => true,
            ]),
        ]);
    }

    public function down(): void
    {
        Schema::table('subscription_plans', function (Blueprint $table): void {
            $table->dropColumn('entitlements');
        });
    }
};
