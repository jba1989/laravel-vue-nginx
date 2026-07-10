FROM node:22-alpine

# CJK 字型：讓容器內 Chromium 跑 Playwright E2E 時能正常渲染中文（否則截圖/錄影會是豆腐框）
RUN apk add --no-cache font-noto-cjk

# Create app directory
WORKDIR /app

COPY app /app

# Install app dependencies
RUN npm install && npm run build

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
