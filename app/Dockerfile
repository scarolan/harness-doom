FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends zip && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# DOOM shareware v1.9 — freely distributable per id Software
COPY DOOM.EXE DOOM1.WAD dosbox.conf ./

# Create .jsdos bundle (zip with DOSBox config + game files for js-dos v8)
RUN mkdir -p .jsdos && \
    cp dosbox.conf .jsdos/dosbox.conf && \
    zip -r /build/doom.jsdos .jsdos/ DOOM.EXE DOOM1.WAD

# --- Final stage ---
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY --from=builder /build/doom.jsdos /usr/share/nginx/html/doom.jsdos

RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && chown nginx:nginx /var/run/nginx.pid

EXPOSE 8080

USER nginx
