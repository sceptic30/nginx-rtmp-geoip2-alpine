# NGINX with TLSv1.3 support &amp; built-in RTMP Media Streaming Server with GeoIP2 country database

[![Build Status](https://www.travis-ci.com/sceptic30/nginx-rtmp-geoip2-alpine.svg?branch=master)](https://www.travis-ci.com/sceptic30/nginx-rtmp-geoip2-alpine) ![Docker Pulls](https://img.shields.io/docker/pulls/admintuts/nginx) ![Nginx Version](https://img.shields.io/badge/Nginx-1.25.2-brightgreen)

## Building The Image

```sh
git clone https://github.com/sceptic30/nginx-rtmp-geoip2-alpine
cd nginx-rtmp-geoip2-alpine
chmod +x docker-entrypoint.sh envsubst-on-templates.sh tune-worker-processes.sh
docker build . -t your_image_tag
```

## Run the image

```sh
docker run -d --rm --name webserver -p 80:3080 -p 443:3443 your_image_tag
```

> Current Image running in non-priviledged mode, under the user 'nginx'

For more details please visit [Admintuts.net](https://admintuts.net/server-admin/docker/custom-nginx-docker-image-geoip2-rtmp-support/#final-nginx-dockerfile-with-geoip2-rtmp-tlsv1-3-support)

## How to enable GeoIP2 database

You must bind mount your database file (GeoLite2-Country.mmdb or GeoLite2-City.mmdb) to the container file system appropriate location. This location is:

```bash
/usr/share/geoip/
```

In a docker-compose file that would look like:

```sh
  webserver:
    image: admintuts/nginx:1.25.2-rtmp-geoip2-alpine
    container_name: webserver
    hostname: webserver
    restart: always
    ports:
        - "80:3080"
        - "443:3443"
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
          image: admintuts/nginx:1.25.2-rtmp-geoip2-alpine
          ports:
          - containerPort: 3080
            name: nginx-http
          - containerPort: 3443
            name: nginx-https
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
