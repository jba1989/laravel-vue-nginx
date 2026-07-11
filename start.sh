#!/usr/bin/env bash

set -e

type=${CONTAINER_TYPE:-app}

if [ "$type" = "app" ]; then
    exec php-fpm
elif [ "$type" = "request" ]; then
    echo "Running the queue: request"
    exec php artisan queue:work redis --verbose --queue=request --sleep=20 --tries=0
elif [ "$type" = "emails" ]; then
    echo "Running the queue: emails"
    exec php artisan queue:work --verbose --queue=emails --sleep=10 --tries=2
elif [ "$type" = "default" ]; then
    echo "Running the queue: default"
    exec php artisan queue:work --verbose --queue=default --sleep=30 --tries=2
elif [ "$type" = "simulation" ]; then
    echo "Running the queue: simulation"
    # database-slow 連線 retry_after=3700 > timeout=3600，避免長時間回測 job 被誤判卡住而重複派發
    # tries=0(無限重試) 會讓真失敗的 job 永不進 failed、batch 永不收斂，改為 2
    exec php artisan queue:work database-slow --verbose --queue=simulation --sleep=10 --tries=2 --timeout=3600
elif [ "$type" = "laborious" ]; then
    echo "Running the queue: laborious"
    exec php artisan queue:work redis --verbose --queue=laborious --sleep=10 --tries=1 --timeout=620
elif [ "$type" = "reverb" ]; then
    echo "Running Reverb WebSocket server"
    exec php artisan reverb:start --host=0.0.0.0 --port=8080
elif [ "$type" = "websocket" ]; then
    echo "Running the queue: websocket"
    while true; do
        php artisan queue:work --verbose --queue=websocket --max-time=3600 --sleep=3 --tries=3
        echo "Websocket worker exited, restarting..."
        sleep 2
    done
elif [ "$type" = "scheduler" ]; then
    echo "Running the scheduler"
    while [ true ]
    do
      php artisan schedule:run >> /dev/null 2>&1 --verbose --no-interaction &
      sleep 60
    done
else
    echo "Could not match the PHP container type \"type\""
    exit 1
fi