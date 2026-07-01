FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY index.html tsconfig.json vite.config.ts ./
COPY src ./src

RUN npm run build

EXPOSE 8500

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "8500"]
