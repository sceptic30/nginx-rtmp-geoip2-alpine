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

## License

MIT

**Free Software, Hell Yeah!**