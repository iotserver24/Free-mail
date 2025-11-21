FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Generates the production-ready Nitro output in .output/
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
# Nuxt listens on 0.0.0.0 automatically when PORT is set
EXPOSE 3000
COPY --from=build /app/.output ./.output
CMD ["node", ".output/server/index.mjs"]

