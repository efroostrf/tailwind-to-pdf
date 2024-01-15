# Use a smaller base image
FROM node:20-alpine3.17 AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat

# Set the working directory
WORKDIR /app

# Copy necessary files
COPY src/prisma ./src/prisma
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
COPY .eslintrc.json .prettierignore* prettierrc.json* ./
COPY next-env.d.ts ./
COPY tsconfig.json tailwind.config.ts postcss.config.js ./
COPY next.config.js ./

RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

FROM base as deps-production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

RUN yarn install --production --ignore-scripts

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED 1

# Copy the source code into the image
COPY . .

# Build the Next.js application with TypeScript type checking
RUN yarn build

# Remove development dependencies after the build
COPY --from=deps-production /app/node_modules ./node_modules

# Runner
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

RUN ls -la

USER nextjs

ARG PORT 3035
EXPOSE ${PORT}

ENV PORT ${PORT}
ENV HOSTNAME "0.0.0.0"

# Run the script when the container starts
# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output
CMD ["node", "server.js"]