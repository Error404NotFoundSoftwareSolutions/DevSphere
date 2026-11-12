FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
ARG NEXT_PUBLIC_HERO_VIDEO=""
ARG NEXT_PUBLIC_DAY_PLATE=""
ARG NEXT_PUBLIC_NIGHT_PLATE=""
ARG NEXT_PUBLIC_MODEL_GLB=""
ARG NEXT_PUBLIC_API_URL=""
ENV NEXT_PUBLIC_HERO_VIDEO=$NEXT_PUBLIC_HERO_VIDEO \
    NEXT_PUBLIC_DAY_PLATE=$NEXT_PUBLIC_DAY_PLATE \
    NEXT_PUBLIC_NIGHT_PLATE=$NEXT_PUBLIC_NIGHT_PLATE \
    NEXT_PUBLIC_MODEL_GLB=$NEXT_PUBLIC_MODEL_GLB \
    NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production PORT=8080 HOSTNAME=0.0.0.0
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
COPY --from=build /app/public ./public
USER node
EXPOSE 8080
CMD ["node", "server.js"]
