FROM node:16-alpine

# Create app directory
WORKDIR /app

COPY app /app

# Install app dependencies
RUN npm install && npm run build

EXPOSE 3000

CMD [ "npm", "start" ]
