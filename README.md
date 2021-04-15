# NGINX with TLSv1.3 support &amp; built-in RTMP Media Streaming Server with GeoIP2 country database.

[![Build Status](https://www.travis-ci.com/sceptic30/nginx-rtmp-geoip2-alpine.svg?branch=master)](https://www.travis-ci.com/sceptic30/nginx-rtmp-geoip2-alpine)

## Building The Image

```sh
git clone https://github.com/sceptic30/nginx-rtmp-geoip2-alpine
cd nginx-rtmp-geoip2-alpine
docker build . -t your_image_tag

```
## Run the image
```sh
docker run -d --rm --name webserver -p 80:80 your_image_tag
```
> Current Image running in non-priviledged mode, under the user 'nginx'

For more details please visit [Admintuts.net](https://admintuts.net/server-admin/docker/custom-nginx-docker-image-geoip2-rtmp-support/#final-nginx-dockerfile-with-geoip2-rtmp-tlsv1-3-support)

## How to enable GeoIP2 database
You must bind mount your database file (GeoLite2-Country.mmdb or GeoLite2-City.mmdb) to the container file system appropriate location. This location is 
```bash
/usr/share/geoip/
```
In a docker-compose file that would look like:
```sh
  webserver:
    image: admintuts/nginx:1.19.10-rtmp-geoip2-alpine
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

## License

MIT

**Free Software, Hell Yeah!**
