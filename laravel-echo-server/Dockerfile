FROM node:16-alpine

RUN npm install -g laravel-echo-server

COPY laravel-echo-server.json /app/

WORKDIR /app

EXPOSE 6001

CMD [ "laravel-echo-server", "start" ]
