FROM alpine:latest

LABEL maintainer="Nikolas S <nikolas@admintuts.net>"

ARG NGINX_GUI=2000
ENV NGINX_GUI=$NGINX_GUI
ENV MAXMIND_VERSION=1.11.0
ENV NGINX_TS_MODULE_VERSION=0.1.1
ENV NGINX_VERSION=1.29.5
# Pre-copy MaxMind Database
COPY GeoLite2-Country.mmdb /usr/share/geoip/

RUN set -x \
    && addgroup -S nginx -g $NGINX_GUI \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u $NGINX_GUI nginx \
    && apk add --no-cache --virtual .build-deps \
        gcc git libc-dev make openssl-dev pcre-dev zlib-dev linux-headers \
        curl gpg dirmngr gnupg libxslt-dev gd-dev geoip-dev perl alpine-sdk \
    && wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VERSION}/libmaxminddb-${MAXMIND_VERSION}.tar.gz \
    && tar xf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
    && cd libmaxminddb-${MAXMIND_VERSION} \
    && ./configure && make && make install \
    && cd / \
    && git clone https://github.com/leev/ngx_http_geoip2_module /ngx_http_geoip2_module \
    && git clone https://github.com/arut/nginx-ts-module.git -b v${NGINX_TS_MODULE_VERSION} /nginx-ts-module \
    && git clone https://github.com/sceptic30/nginx-rtmp-module.git /nginx-rtmp-module \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg_keys="13C82A63B603576156E30A4EA0EA981B66B0D967 43387825DDB1BB97EC36BA5D007C8D7C15D87369 D6786CE303D9A9022998DC038086060F2B718707" \
    && for server in keyserver.ubuntu.com pgp.mit.edu keys.openpgp.org; do \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys $gpg_keys && break; \
    done \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --add-dynamic-module=/ngx_http_geoip2_module \
        --add-module=/nginx-ts-module \
        --add-dynamic-module=/nginx-rtmp-module \
        --with-cc-opt="-I/usr/local/include" \
        --with-ld-opt="-Wl,-rpath,/usr/local/lib -L/usr/local/lib" \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/* 2>/dev/null \
            | tr ',' '\n' | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps tzdata curl ca-certificates \
    && apk del .build-deps \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir -p /var/www/html /etc/nginx/conf.d /usr/share/nginx /docker-entrypoint.d \
    && chown -R nginx:nginx /etc/nginx /var/log/nginx /var/cache/nginx /usr/share/nginx /var/www \
    && rm -rf /usr/src/* /ngx_http_geoip2_module /nginx-ts-module /nginx-rtmp-module /nginx.tar.gz

COPY nginx.conf /etc/nginx/nginx.conf
COPY vh-default.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
USER nginx
EXPOSE 3080 3443 3443/udp
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
