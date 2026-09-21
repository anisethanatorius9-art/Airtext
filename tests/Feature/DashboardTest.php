<?php

use App\Models\User;

test('anyone can open the AirText workspace', function () {
    $response = $this->get(route('home'));
    $response->assertOk();
});

test('the old dashboard path redirects to AirText', function () {
    $user = User::factory()->create();
    $this->actingAs($user);

    $response = $this->get(route('dashboard'));
    $response->assertRedirect(route('home'));
});
