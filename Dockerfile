FROM --platform=linux/amd64 node:20-alpine
WORKDIR /app

COPY ./package.json ./

RUN npm install --silent

COPY . ./

# TODO: Make it 80
EXPOSE 80

CMD ["npm", "start"]
