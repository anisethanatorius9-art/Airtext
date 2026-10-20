<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('subscription_plans', function (Blueprint $table): void {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->unsignedInteger('price_tzs');
            $table->unsignedSmallInteger('duration_days')->nullable();
            $table->text('description');
            $table->json('features');
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('subscriptions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('subscription_plan_id')->constrained()->restrictOnDelete();
            $table->foreignId('shop_transaction_id')->nullable()->unique()->constrained()->nullOnDelete();
            $table->string('status')->default('pending_payment')->index();
            $table->timestamp('activated_at')->nullable();
            $table->timestamp('ends_at')->nullable()->index();
            $table->timestamps();
            $table->index(['user_id', 'status']);
        });

        $now = now();
        DB::table('subscription_plans')->insert([
            [
                'code' => 'free_starter',
                'name' => 'Free Starter',
                'price_tzs' => 0,
                'duration_days' => null,
                'description' => 'Core messaging for everyday use.',
                'features' => json_encode(['Core chats', 'Standard messaging', 'No AI bots']),
                'is_active' => true,
                'sort_order' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'code' => 'pro_monthly',
                'name' => 'Pro Pass',
                'price_tzs' => 10000,
                'duration_days' => 30,
                'description' => 'Pro features billed every 30 days.',
                'features' => json_encode(['All AI chatbots', 'Priority messages', '5 GB media storage']),
                'is_active' => true,
                'sort_order' => 2,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'code' => 'pro_quarterly',
                'name' => 'Pro Pass · 3 months',
                'price_tzs' => 25000,
                'duration_days' => 90,
                'description' => 'Three months of Pro features at a reduced price.',
                'features' => json_encode(['All AI chatbots', 'Priority messages', '5 GB media storage', 'Save TZS 5,000']),
                'is_active' => true,
                'sort_order' => 3,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'code' => 'biz_monthly',
                'name' => 'Business Unlimited',
                'price_tzs' => 50000,
                'duration_days' => 30,
                'description' => 'Business tools billed every 30 days.',
                'features' => json_encode(['Business bots', 'Auto-reply automation', 'Broadcast SMS and chat', 'Unlimited storage']),
                'is_active' => true,
                'sort_order' => 4,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'code' => 'biz_yearly',
                'name' => 'Enterprise · Annual',
                'price_tzs' => 450000,
                'duration_days' => 365,
                'description' => 'Annual business access with dedicated support.',
                'features' => json_encode(['Business bots', 'Auto-reply automation', 'Broadcast SMS and chat', 'Unlimited storage', 'Dedicated support', 'API integration assistance']),
                'is_active' => true,
                'sort_order' => 5,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ]);

    }

    public function down(): void
    {
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('subscription_plans');
    }
};
