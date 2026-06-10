# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm config set fetch-retry-maxtimeout 600000 -g && \
    npm config set fetch-retry-mintimeout 10000 -g && \
    npm install --network-timeout=1000000

COPY . .
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
ENV NODE_OPTIONS="--max-old-space-size=4096"
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
