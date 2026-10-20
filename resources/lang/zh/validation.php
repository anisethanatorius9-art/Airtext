<?php

return [
    'required' => ':attribute不能为空。',
    'required_without' => '当 :values 不存在时，:attribute不能为空。',
    'email' => ':attribute必须是有效的电子邮箱地址。',
    'digits' => ':attribute必须包含:digits位数字。',
    'in' => '所选的:attribute无效。',
    'max' => [
        'array' => ':attribute最多只能有:max项。',
        'file' => ':attribute不能大于:max千字节。',
        'numeric' => ':attribute不能大于:max。',
        'string' => ':attribute不能超过:max个字符。',
    ],
    'regex' => ':attribute格式无效。',
    'size' => ['string' => ':attribute必须为:size个字符。'],
    'unique' => ':attribute已经被使用。',
    'attributes' => [
        'code' => '验证码',
        'email' => '电子邮箱',
        'name' => '姓名',
        'phone_number' => '电话号码',
    ],
];
