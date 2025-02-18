FROM --platform=linux/amd64 node:20-alpine
WORKDIR /app

COPY ./package.json ./

RUN npm install --silent

COPY . ./

EXPOSE 80

CMD ["npm", "start"]
