FROM node:alpine

WORKDIR /app

COPY . .

RUN npm install -g --production

EXPOSE 8080

USER node

CMD ["node", "./index.js"]
