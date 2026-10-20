<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Contact;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ContactController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'data' => Contact::query()
                ->orderBy('name')
                ->get(['id', 'name', 'phone_number', 'payload_prefix', 'is_registered']),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone_number' => ['required', 'string', 'regex:/^\\+[1-9]\\d{7,14}$/'],
            'payload_prefix' => ['required', 'in:MSG:,STAT:,ACK:'],
        ]);

        $contact = Contact::updateOrCreate(
            ['phone_number' => $validated['phone_number']],
            [
                'name' => trim($validated['name']),
                'status_bio' => 'SMS contact',
                'payload_prefix' => $validated['payload_prefix'],
                'is_registered' => false,
            ],
        );

        return response()->json([
            'data' => $contact->only(['id', 'name', 'phone_number', 'payload_prefix', 'is_registered']),
        ], 201);
    }
}
