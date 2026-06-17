# Production image for the Student Records app.
FROM node:22-alpine

WORKDIR /usr/src/app

# Install dependencies first to leverage Docker layer caching.
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

ENV NODE_ENV=production
EXPOSE 3000

# Basic container healthcheck hitting the shallow liveness endpoint.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
