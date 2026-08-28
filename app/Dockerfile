FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY favicon.png /usr/share/nginx/html/favicon.png
COPY DOOM1.WAD /usr/share/nginx/html/doom1.wad
COPY default.cfg /usr/share/nginx/html/default.cfg
COPY wasm-artifacts/doom.js /usr/share/nginx/html/doom.js
COPY wasm-artifacts/doom.wasm /usr/share/nginx/html/doom.wasm
COPY e1m1.mp3 /usr/share/nginx/html/e1m1.mp3

RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    sed -i 's|/run/nginx.pid|/tmp/nginx.pid|g' /etc/nginx/nginx.conf || true && \
    touch /tmp/nginx.pid && chown nginx:nginx /tmp/nginx.pid

EXPOSE 8080
USER nginx
