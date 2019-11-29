FROM devgeniem/base:edge
MAINTAINER Ville Pietarinen - Geniem Oy <ville.pietarinen-nospam@geniem.com>

# Build Arguments for openresty/nginx
ARG RESTY_VERSION="1.15.8.2"
ARG RESTY_OPENSSL_VERSION="1.1.1c"

ARG PAGESPEED_VERSION="1.13.35.2"

# Fix apt-get and show colors
ARG DEBIAN_FRONTEND=noninteractive
ARG TERM=xterm-color

ARG RESTY_CONFIG_OPTIONS="\
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
    --with-http_geoip_module=dynamic \

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

    --add-module=/tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable \
    --add-module=/tmp/ngx_cache_purge-2.3 \
    --with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} \
    "


# These are only needed during the installation
ARG BUILD_DEPS='build-essential curl libreadline-dev libncurses5-dev libpcre3-dev libgeoip-dev zlib1g-dev ca-certificates uuid-dev'

# Install base utils
RUN \
    apt-get update && \
    apt-get -y install $BUILD_DEPS --no-install-recommends && \

    cd /tmp/ && \

    ### Download Tarballs ###
    # Download PageSpeed
    echo "Downloading PageSpeed..." && \
    curl -L https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}-stable.tar.gz | tar -zx && \

    ls -lah && \

    # psol needs to be inside ngx_pagespeed module
    # Download PageSpeed Optimization Library and extract it to nginx source dir
    #cd /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-stable/ && \
    cd /tmp/incubator-pagespeed-ngx-${PAGESPEED_VERSION}-stable/ && \
    echo "Downloading PSOL..." && \
    curl -L https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}-x64.tar.gz | tar -zx && \

    cd /tmp/ && \
    # Download Nginx cache purge module
    echo "Downloading Nginx cache purge module..." && \
    curl -L http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz | tar -zx && \

    # Download OpenSSL
    echo "Downloading OpenSSL..." && \
    curl -L https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz | tar -zx && \

    # Download Openresty bundle
    echo "Downloading openresty..." && \
    curl -L https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz | tar -zx && \

    # Download custom redis module with AUTH support
    echo "Downloading ngx_http_redis..." && \
    curl -L https://github.com/onnimonni/ngx_http_redis-0.3.7/archive/master.tar.gz | tar -zx && \

    # Use all cores available in the builds with -j${NPROC} flag
    readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)  && \
    echo "using up to $NPROC threads" && \

    ### Configure Nginx ###
    cd openresty-${RESTY_VERSION} && \
    ./configure -j${NPROC} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} && \

    # Build Nginx
    make -j${NPROC} && \
    make -j${NPROC} install && \

    mkdir -p /var/lib/nginx /var/log/nginx && \

    ## Cleanup
    rm -rf /var/lib/apt/lists/* && \
    apt-get remove --purge -y $BUILD_DEPS $(apt-mark showauto) && \
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
