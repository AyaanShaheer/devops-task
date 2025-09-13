# ---- Build stage ----
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# ---- Run stage ----
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY app.js package*.json ./
COPY logoswayatt.png ./
EXPOSE 3000
CMD ["node","app.js"]
