# build stage
FROM ghcr.io/linuxserver/baseimage-alpine:3.18 as build-stage

WORKDIR /app

COPY package*.json ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build

# production stage
FROM ghcr.io/linuxserver/baseimage-alpine:3.18

ARG PUID
ARG PGID
ARG PORT
ARG INIT_ASSETS
ARG SUBFOLDER

RUN addgroup -S lighttpd -g ${PGID} && adduser -D -S -u ${PUID} lighttpd lighttpd && \
    apk add -U --no-cache lighttpd

WORKDIR /www

COPY lighttpd.conf /lighttpd.conf
COPY entrypoint.sh /entrypoint.sh
COPY --from=build-stage --chown=${PUID}:${PGID} /app/dist /www/
COPY --from=build-stage --chown=${PUID}:${PGID} /app/dist/assets /www/default-assets

USER ${UID}:${GID}

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/ || exit 1

EXPOSE ${PORT}

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
