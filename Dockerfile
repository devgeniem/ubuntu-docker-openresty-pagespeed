FROM devgeniem/base:jammy

LABEL maintainer="Jussi Alanen - Hion Digital Oy <jussi.alanen@hiondigital.com>"

# Version of packages
ARG RESTY_VERSION="1.21.4.1"
ARG OPENSSL_VERSION="1.1.1w"
ARG PAGESPEED_VERSION="1.13.35.2"
ARG PSOL="jammy"
ARG MAKE_J=4

# Fix apt-get and show colors
ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=xterm-color

# Build deps
ARG BUILD_DEPS='build-essential git wget curl make perl libreadline-dev libncurses5-dev libpcre3-dev libssl-dev libgeoip-dev zlib1g-dev ca-certificates uuid-dev'

RUN apt-get update && apt-get install -y $BUILD_DEPS --no-install-recommends

RUN mkdir -p /usr/local/src/nginx && \
    cd /tmp && \

    # Download Openresty bundle
    echo "Downloading openresty..." && \
    curl -L https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz | tar -zx && \

    # Download Pagespeed for Nginx
    cd /tmp && \
    echo "Downloading PageSpeed for Openresty/Nginx bundle..." && \
    git clone https://github.com/apache/incubator-pagespeed-ngx.git && \
    cd incubator-pagespeed-ngx/ && \
    git checkout latest-stable && \

    # Download the correct PSOL extension for PageSpeed (for Ubuntu)
    cd /tmp && \
    wget http://www.tiredofit.nl/psol-${PSOL}.tar.xz && \
    tar -xvf psol-${PSOL}.tar.xz && \
    cp -r psol /tmp/incubator-pagespeed-ngx && \

    # Download OpenSSL
    cd /tmp && \
    echo "Downloading OpenSSL..." && \
    curl -L https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz | tar -zx && \

    # Build in additional Nginx modules
    cd /tmp && \
    git clone https://github.com/FRiCKLE/ngx_cache_purge.git && \

    cd openresty-${RESTY_VERSION} && \
    # cd /tmp/nginx-$NGINX_VERSION && \
    ./configure -j${MAKE_J} ${_RESTY_CONFIG_DEPS} \
    --with-compat \
    --with-http_addition_module \
    --with-http_auth_request_module \
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

    --with-file-aio \
    --with-ipv6 \
    --with-pcre-jit \
    --with-stream \
    --with-stream_ssl_module \
    --with-threads \

    --without-http_autoindex_module \
    --without-http_browser_module \
    --without-http_userid_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --without-http_split_clients_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_referer_module \

    --without-http_redis_module \

    --user=nginx \
    --group=nginx \

    --sbin-path=/usr/sbin \
    --modules-path=/usr/lib/nginx \

    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx/nginx.lock \

    --http-fastcgi-temp-path=/tmp/nginx/fastcgi \
    --http-proxy-temp-path=/tmp/nginx/proxy \
    --http-client-body-temp-path=/tmp/nginx/client_body \

    --with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
    --add-module=/tmp/ngx_cache_purge \
    --add-module=/tmp/incubator-pagespeed-ngx && \

    make -j${MAKE_J} && \
    make -j${MAKE_J} install && \

    mkdir -p /var/lib/nginx /var/log/nginx && \

    ## Cleanup
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/log/apt/*

RUN \
    # Temp directory
    mkdir /tmp/nginx/ \
    mkdir -p /tmp/nginx/pagespeed/images/ \

    # Symlink modules path to config path for easier usage
    && ln -sf /usr/lib/nginx /etc/nginx/modules \

    # Create nginx group
    && groupadd -g 8888 nginx \
    && useradd -u 8888 -g nginx nginx \

    # Symlink nginx logs to system output
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
