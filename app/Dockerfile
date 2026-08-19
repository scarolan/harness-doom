FROM alpine:3.20 AS builder

RUN apk add --no-cache curl zip

WORKDIR /build

# Download DOOM shareware v1.9 (freely distributable)
# The shareware WAD is ~4.2MB and explicitly free to redistribute per id Software
RUN curl -fSL "https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad" -o DOOM1.WAD

# Download DOOM.EXE from the shareware package
RUN curl -fSL "https://archive.org/download/DoomsharewareEpisode/doom.ZIP" -o doom-shareware.zip && \
    unzip -jo doom-shareware.zip "*/DOOM.EXE" -d . || \
    unzip -jo doom-shareware.zip "DOOM.EXE" -d . && \
    rm doom-shareware.zip

# Create .jsdos bundle (zip with specific structure for js-dos v8)
RUN mkdir -p .jsdos && \
    printf '[autoexec]\nmount c .\nc:\nDOOM.EXE\n' > .jsdos/dosbox.conf && \
    zip -r /build/doom.jsdos .jsdos/ DOOM.EXE DOOM1.WAD

# --- Final stage ---
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY --from=builder /build/doom.jsdos /usr/share/nginx/html/doom.jsdos

EXPOSE 8080

USER nginx
