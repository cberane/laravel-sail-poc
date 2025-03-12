<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test-event', function () {
    broadcast(new App\Events\TestEvent('Hello World'));

    return 'Event has been sent!';
});
