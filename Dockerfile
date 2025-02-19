FROM --platform=linux/arm64/v8 node:20-alpine
WORKDIR /app

COPY ./package.json ./

RUN npm install --silent

COPY . ./

EXPOSE 80

CMD ["npm", "start"]
