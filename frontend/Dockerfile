# Build stage
FROM node:20-alpine AS builder
# SECURITY: Use Alpine for smaller attack surface

WORKDIR /app

# SECURITY: Copy package files first for better layer caching
COPY package*.json ./
RUN npm ci --only=production=false

COPY . .
RUN npm run build

# Runtime stage  
FROM node:20-alpine AS runner
WORKDIR /app

# SECURITY: Set production environment
ENV NODE_ENV=production

# SECURITY FIX: Create non-root user
# Original ran as root which is dangerous if container is compromised
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy only necessary files from build stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# SECURITY: Set ownership to non-root user
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

# ADDED: Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

CMD ["node", "server.js"]
