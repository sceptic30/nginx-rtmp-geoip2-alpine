FROM alpine:latest

LABEL maintainer="Nikolas S <nikolas@admintuts.net>"
# Host Specific Variable
ARG NGINX_GUI=2000
ENV NGINX_GUI $NGINX_GUI

# ngx_http_geoip2_module & libmaxminddb installation

ENV MAXMIND_VERSION=1.7.1
ENV NGINX_TS_MODULE_VERSION=0.1.1
COPY GeoLite2-Country.mmdb /usr/share/geoip/

RUN set -x \
  && apk --no-cache update \
  && apk --no-cache upgrade --available \
  && apk --no-cache add --virtual .build-deps \
    alpine-sdk \
    perl \
  && git clone https://github.com/leev/ngx_http_geoip2_module /ngx_http_geoip2_module \
  && git clone https://github.com/arut/nginx-ts-module.git -b v${NGINX_TS_MODULE_VERSION} /nginx-ts-module \
  && wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VERSION}/libmaxminddb-${MAXMIND_VERSION}.tar.gz \
  && tar xf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
  && cd libmaxminddb-${MAXMIND_VERSION} \
  && ./configure \
  && make \
  && make check \
  && make install \
  && apk del .build-deps

RUN ldconfig || :

# Nginx installation 

ENV NGINX_VERSION 1.23.4
RUN GPG_KEYS=13C82A63B603576156E30A4EA0EA981B66B0D967 \
&& CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --with-openssl-opt="enable-tls1_3" \
    --with-openssl-opt=no-nextprotoneg \
    --add-dynamic-module=/ngx_http_geoip2_module \
    --add-module=/nginx-ts-module \
    --add-dynamic-module=/nginx-rtmp-module \
" \
    && addgroup -S nginx -g $NGINX_GUI \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx -u $NGINX_GUI nginx \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gpg \
        dirmngr \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && found=''; \
    for server in \
        keyserver.ubuntu.com \
        pgp.mit.edu \
        keys.openpgp.org \
    ; do \
        echo "Fetching GPG key $GPG_KEYS from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
    gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
    && mkdir -p /usr/src \
    && git clone https://github.com/sceptic30/nginx-rtmp-module.git \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure $CONFIG --with-debug \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
    && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
    && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
    && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
    && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && rm -rf /usr/src/nginx-$NGINX_VERSION \
    && rm -rf /usr/src/nginx-rtmp-module \
    && cd /                 \
    && rm -rf libmaxminddb-${MAXMIND_VERSION} \
    && rm -rf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
    && rm -rf ngx_http_geoip2_module \
    && rm -rf nginx-rtmp-module \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
    # Bring in tzdata and openssl so users could set the timezones and tls1.3 through the environment
    # variables
    && apk add --no-cache tzdata \
    && mkdir /docker-entrypoint.d \
    && apk add --no-cache curl ca-certificates \
    # Create access and error logging
    && touch /var/log/nginx/access.log \
    && touch /var/log/nginx/error.log \ 
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    # Give nginx users appropriate permissions to eccential directories recursively
    && mkdir /etc/letsencrypt \
    && mkdir /var/lib/letsencrypt \
    && mkdir /var/log/letsencrypt \
    && mkdir -p /var/www/html \
    && chown -R nginx:nginx /var/log \
    && chown -R nginx:nginx /var/cache/nginx \
    && chown -R nginx:nginx /usr/share/nginx \
    && chown -R nginx:nginx /etc/nginx \
    && chown -R nginx:nginx /var/www \
    && chown -R root:nginx /etc/letsencrypt \
    && touch /var/run/nginx.pid  \
    && chown nginx:nginx /var/run/nginx.pid \
    && chmod 770 /var/run/nginx.pid \
    && chown root:nginx /run \
    && chmod 770 -R /run \
    && chmod 755 /etc/nginx \
    && chmod 755 -R /var/log/nginx \
    && chmod 770 -R /var/log/letsencrypt \
    && chmod 755 -R /usr/share/nginx \
    && chmod 755 -R /etc/nginx/conf.d \
    && chmod 755 -R /var/www

COPY nginx.conf /etc/nginx/nginx.conf
COPY vh-default.conf /etc/nginx/conf.d/default.conf
COPY docker-entrypoint.sh /
COPY envsubst-on-templates.sh /docker-entrypoint.d
COPY tune-worker-processes.sh /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]
USER nginx
EXPOSE 3080 3443
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
