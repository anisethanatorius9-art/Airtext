<?php

return [
    'required' => 'Le champ :attribute est obligatoire.',
    'required_without' => 'Le champ :attribute est obligatoire lorsque :values est absent.',
    'email' => 'Le champ :attribute doit être une adresse e-mail valide.',
    'digits' => 'Le champ :attribute doit contenir :digits chiffres.',
    'in' => 'La valeur sélectionnée pour :attribute est invalide.',
    'max' => [
        'array' => 'Le champ :attribute ne peut pas contenir plus de :max éléments.',
        'file' => 'Le fichier :attribute ne peut pas dépasser :max kilo-octets.',
        'numeric' => 'La valeur de :attribute ne peut pas dépasser :max.',
        'string' => 'Le champ :attribute ne peut pas dépasser :max caractères.',
    ],
    'regex' => 'Le format du champ :attribute est invalide.',
    'size' => ['string' => 'Le champ :attribute doit contenir :size caractères.'],
    'unique' => 'La valeur du champ :attribute est déjà utilisée.',
    'attributes' => [
        'code' => 'code',
        'email' => 'adresse e-mail',
        'name' => 'nom',
        'phone_number' => 'numéro de téléphone',
    ],
];
