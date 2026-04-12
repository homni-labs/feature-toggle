# Stage 1 — Build Flutter web
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.41.6
ARG BASE_HREF=/

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m flutter
USER flutter

ENV FLUTTER_HOME=/home/flutter/sdk
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone --depth 1 --branch $FLUTTER_VERSION \
    https://github.com/flutter/flutter.git $FLUTTER_HOME \
    && flutter precache --web --no-android --no-ios --no-linux --no-macos --no-windows --no-fuchsia \
    && flutter doctor -v

WORKDIR /home/flutter/app
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY --chown=flutter:flutter . .
RUN flutter build web --release --base-href "$BASE_HREF"

# Stage 2 — Serve with nginx
FROM nginx:1.27-alpine

COPY --from=build /home/flutter/app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -fsS http://localhost/ > /dev/null || exit 1
