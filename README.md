# NGINX with HTTP/3 (QUIC), TLSv1.3, RTMP Media Streaming & GeoIP2 country database

[![Build](https://github.com/sceptic30/nginx-rtmp-geoip2-alpine/actions/workflows/build.yml/badge.svg)](https://github.com/sceptic30/nginx-rtmp-geoip2-alpine/actions/workflows/build.yml) ![Docker Pulls](https://img.shields.io/docker/pulls/admintuts/nginx) ![Nginx Version](https://img.shields.io/badge/Nginx-1.29.5-brightgreen)

## Features

- **HTTP/3 (QUIC)** -- Built with `--with-http_v3_module` for next-gen transport over UDP
- **HTTP/2** -- Full HTTP/2 support
- **TLSv1.3** -- Modern TLS out of the box
- **RTMP** -- Live media streaming via the RTMP module
- **GeoIP2** -- MaxMind GeoLite2 country database pre-loaded; city database supported via bind mount
- **Non-privileged** -- Runs as the `nginx` user by default

## Building The Image

```sh
git clone https://github.com/sceptic30/nginx-rtmp-geoip2-alpine
cd nginx-rtmp-geoip2-alpine
chmod +x docker-entrypoint.sh envsubst-on-templates.sh tune-worker-processes.sh
docker build . -t your_image_tag
```

## Run the image

```sh
docker run -d --rm --name webserver \
  -p 80:3080 \
  -p 443:3443 \
  -p 443:3443/udp \
  your_image_tag
```

> Port `3443/udp` is required for HTTP/3 (QUIC). The container exposes both TCP and UDP on port 3443.
> Current image runs in non-privileged mode under the user `nginx`.

For more details please visit [Admintuts.net](https://admintuts.net/server-admin/docker/custom-nginx-docker-image-geoip2-rtmp-support/#final-nginx-dockerfile-with-geoip2-rtmp-tlsv1-3-support)

## How to enable HTTP/3 (QUIC)

This image is compiled with `--with-http_v3_module`, so HTTP/3 is ready to use. To enable it, add a server block that listens on a QUIC (UDP) port alongside the standard TLS (TCP) port, and advertise HTTP/3 via the `Alt-Svc` header.

Create or edit your site configuration (e.g. `/etc/nginx/conf.d/default.conf`):

```nginx
server {
    listen       3443 ssl;       # HTTP/1.1 + HTTP/2 over TLS (TCP)
    listen       3443 quic;      # HTTP/3 over QUIC (UDP)
    http2        on;
    server_name  example.com;

    ssl_certificate      /etc/nginx/ssl/cert.pem;
    ssl_certificate_key  /etc/nginx/ssl/key.pem;
    ssl_protocols        TLSv1.2 TLSv1.3;

    # Advertise HTTP/3 support to clients
    add_header Alt-Svc 'h3=":3443"; ma=86400' always;

    # Optional: improve QUIC performance
    ssl_early_data on;
    quic_gso       on;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
}
```

Key points:

- **`listen 3443 quic`** enables QUIC/HTTP/3 on UDP. It must share the same port number as the TLS listener.
- **`Alt-Svc`** header tells browsers that HTTP/3 is available. Browsers connect over TCP first, then upgrade to QUIC on subsequent requests.
- **`ssl_early_data on`** enables 0-RTT for faster connection resumption (consider the replay-attack trade-off for non-idempotent requests).
- **`quic_gso on`** enables UDP Generic Segmentation Offload for better throughput on supported kernels.
- Make sure your firewall allows **UDP traffic** on the QUIC port (3443/udp).

## How to enable GeoIP2 database

You must bind mount your database file (GeoLite2-Country.mmdb or GeoLite2-City.mmdb) to the container file system appropriate location. This location is:

```bash
/usr/share/geoip/
```

In a docker-compose file that would look like:

```sh
  webserver:
    image: admintuts/nginx:1.29.5-rtmp-geoip2-alpine
    container_name: webserver
    hostname: webserver
    restart: always
    ports:
        - "80:3080"
        - "443:3443"
        - "443:3443/udp"
    volumes:
        - ./geoip-db/GeoLite2-City.mmdb:/usr/share/geoip/GeoLite2-City.mmdb
    networks:
        - default
```

## Running With Kubernetes Statefulset

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx
  namespace: production
  labels:
    app: nginx
spec:
  serviceName: nginx
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: admintuts/nginx:1.29.5-rtmp-geoip2-alpine
          ports:
          - containerPort: 3080
            name: nginx-http
            protocol: TCP
          - containerPort: 3443
            name: nginx-https
            protocol: TCP
          - containerPort: 3443
            name: nginx-quic
            protocol: UDP
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "180m"
#          volumeMounts:
#          - name: webserver-config
#            mountPath: /etc/nginx/nginx.conf
#            subPath: nginx.conf
#          - name: webserver-config
#            mountPath: /etc/nginx/conf.d/nginx-http.conf
#            subPath: nginx-http.conf
#          - mountPath: /var/www/html
#            name: nginx-vol
      restartPolicy: Always
#      volumes:
#        - name: webserver-config
#          configMap:
#            name: webserver-config
#        - name: nginx-vol
#          persistentVolumeClaim:
#             claimName: nginx-pvc
```

## License

MIT

**Free Software, Hell Yeah!**
