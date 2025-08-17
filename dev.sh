#!/usr/bin/env bash
set -e
( cd backend  && php artisan serve --host=127.0.0.1 --port=8000 ) &
( cd backend  && php artisan queue:work --tries=1 ) &
( cd backend  && php artisan schedule:work ) &
( cd frontend && npm run dev ) &
wait
