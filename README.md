# ubuntu-docker-openresty-pagespeed

docker-base plus OpenResty (nginx) compiled from source.

> PageSpeed is not included; the repo name is historical.

Layer 2 of 3 in the devgeniem web image stack:
1. [docker-base](https://github.com/devgeniem/docker-base): Ubuntu + s6 base
2. **[ubuntu-docker-openresty-pagespeed](https://github.com/devgeniem/ubuntu-docker-openresty-pagespeed)**: OpenResty
3. [ubuntu-docker-wordpress](https://github.com/devgeniem/ubuntu-docker-wordpress): PHP-FPM + WordPress tooling

## Includes
- OpenResty 1.31.8.1 with OpenSSL 3.5.9
- [ngx_cache_purge](https://github.com/nginx-modules/ngx_cache_purge)
- `nginx` user/group (UID/GID 8888); logs to stdout/stderr

## Build
Requires `devgeniem/base` ([build the stack](https://github.com/devgeniem/docker-base#build)).
```bash
docker buildx build --platform linux/amd64 -t devgeniem/ubuntu-docker-openresty-pagespeed .
```
