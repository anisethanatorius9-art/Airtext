<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class PrivacyVisibility
{
    /** @var array<int, array<int, true>> */
    private array $contactsByUser = [];

    public function canView(User $profileOwner, User $viewer, ?string $visibility): bool
    {
        if ($profileOwner->is($viewer)) {
            return true;
        }

        return match ($visibility ?? 'My contacts') {
            'Everyone' => true,
            'Contacts', 'My contacts', 'My contacts except...' => $this->isContact($profileOwner, $viewer),
            default => false,
        };
    }

    private function isContact(User $profileOwner, User $viewer): bool
    {
        if (! isset($this->contactsByUser[$profileOwner->id])) {
            $this->contactsByUser[$profileOwner->id] = DB::table('user_contacts')
                ->where('user_id', $profileOwner->id)
                ->pluck('contact_user_id')
                ->mapWithKeys(fn ($id): array => [(int) $id => true])
                ->all();
        }

        return isset($this->contactsByUser[$profileOwner->id][$viewer->id]);
    }
}
