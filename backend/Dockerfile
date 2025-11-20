## ---- Dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app

# Install dependencies using package-lock for reproducibility
COPY package*.json ./
RUN npm ci

## ---- Build ----
FROM node:20-alpine AS build
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY tsconfig.json ./
COPY swagger.json ./swagger.json
COPY src ./src

RUN npm run build

## ---- Production Runner ----
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./

# Copy only production dependencies
COPY --from=deps /app/node_modules ./node_modules
RUN npm prune --omit=dev

# Copy compiled output
COPY --from=build /app/dist ./dist
COPY swagger.json ./swagger.json

EXPOSE 3000
CMD ["node", "dist/index.js"]

