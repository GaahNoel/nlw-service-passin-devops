# Definindo etapa base
FROM node:20 AS base

RUN npm i -g pnpm

# Definindo próxima etapa usando a etapa base para instalação de dependencias
FROM base as dependencies

WORKDIR /usr/src/app

COPY package.json pnpm-lock.yaml ./

RUN pnpm install

FROM base as build 

WORKDIR /usr/src/app

COPY . .
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

RUN pnpm build 
RUN pnpm prune --prod

FROM node:20-alpine3.19 as deploy

WORKDIR /usr/src/app

RUN npm i -g pnpm prisma 

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

ENV DATABASE_URL="file:./dev.db"
ENV API_BASE_URL="http://localhost:3333"

RUN pnpm prisma generate

EXPOSE 3333

CMD ['pnpm', 'start']