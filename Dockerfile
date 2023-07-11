# build stage
FROM node:lts-alpine as build-stage

WORKDIR /app

COPY package*.json ./
RUN yarn install --frozen-lockfile

COPY . .
RUN yarn build

# production stage
FROM ghcr.io/linuxserver/baseimage-alpine:3.18

ENV GID 1003
ENV UID 1003
ENV PORT 8080
ENV SUBFOLDER "/_"
ENV INIT_ASSETS 1

RUN addgroup -g ${GID} -S lighttpd && adduser -D -u ${UID} -S lighttpd -G lighttpd && \
    apk add -U --no-cache lighttpd

WORKDIR /www

COPY lighttpd.conf /lighttpd.conf
COPY --chmod=555 entrypoint.sh /entrypoint.sh
COPY --from=build-stage --chown=${UID}:${GID} /app/dist /www/
COPY --from=build-stage --chown=${UID}:${GID} /app/dist/assets /www/default-assets

RUN ls -la / && getent passwd && getent group

USER ${UID}:${GID}

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/ || exit 1

EXPOSE ${PORT}

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
