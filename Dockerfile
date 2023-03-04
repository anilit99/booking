# Get NPM packages
FROM node:19-alpine AS dependencies
RUN apk add --no-cache libc6-compat
WORKDIR /book-hotels
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Rebuild the source code only when needed
FROM node:19-alpine AS builder
WORKDIR /book-hotels
COPY . .
COPY --from=dependencies /book-hotels/node_modules ./node_modules
RUN npm run build

# Production image, copy all the files and run next
FROM node:14-alpine AS runner
WORKDIR /book-hotels

ENV NODE_ENV production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

COPY --from=builder --chown=nextjs:nodejs /book-hotels/.next ./.next
COPY --from=builder /book-hotels/node_modules ./node_modules
COPY --from=builder /book-hotels/package.json ./package.json

USER nextjs
EXPOSE 3000

RUN node -v
RUN npm -v


CMD ["npm", "start"]