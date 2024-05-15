#!/usr/bin/env bash

set -e

type=${CONTAINER_TYPE:-app}

if [ "$type" = "app" ]; then
    exec php-fpm
elif [ "$type" = "request" ]; then
    echo "Running the queue: request"
    php artisan queue:work redis --verbose --queue=request --sleep=3 --tries=0
elif [ "$type" = "emails" ]; then
    echo "Running the queue: emails"
    php artisan queue:work --verbose --queue=emails --sleep=10 --tries=1
elif [ "$type" = "simulation" ]; then
    echo "Running the queue: simulation"
    php artisan queue:work --verbose --queue=simulation --sleep=10 --tries=0
elif [ "$type" = "websocket" ]; then
    echo "Running the queue: websocket"
    php artisan queue:work redis --verbose --queue=websocket
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